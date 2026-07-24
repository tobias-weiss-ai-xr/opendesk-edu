"""Keycloak Admin API client for user and group management.

Uses OAuth2 client credentials grant for authentication.
All methods raise KeycloakClientError on API failures.
"""

from __future__ import annotations

import os
import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Optional

import httpx

logger = logging.getLogger("keycloak_client")


class KeycloakClientError(Exception):
    """Raised when Keycloak Admin API returns an error."""


@dataclass
class KeycloakConfig:
    """Configuration for Keycloak Admin API access."""
    base_url: str
    realm: str
    client_id: str = "admin-cli"
    client_secret: str = ""
    username: str = ""
    password: str = ""
    verify_ssl: bool = True
    timeout: float = 30.0

    @classmethod
    def from_env(cls) -> "KeycloakConfig":
        """Create config from environment variables."""
        return cls(
            base_url=os.environ.get("KEYCLOAK_URL", "https://id.opendesk.internal"),
            realm=os.environ.get("KEYCLOAK_REALM", "opendesk"),
            client_id=os.environ.get("KEYCLOAK_CLIENT_ID", "admin-cli"),
            client_secret=os.environ.get("KEYCLOAK_CLIENT_SECRET", ""),
            username=os.environ.get("KEYCLOAK_ADMIN_USER", ""),
            password=os.environ.get("KEYCLOAK_ADMIN_PASSWORD", ""),
            verify_ssl=os.environ.get("KEYCLOAK_VERIFY_SSL", "true").lower() == "true",
            timeout=float(os.environ.get("KEYCLOAK_TIMEOUT", "30")),
        )


class KeycloakClient:
    """Client for Keycloak Admin API operations."""

    def __init__(self, config: KeycloakConfig) -> None:
        self.config = config
        self._token: Optional[str] = None
        self._token_expiry: Optional[datetime] = None
        self._admin_url = f"{config.base_url}/admin/realms/{config.realm}"

    def _get_token(self) -> str:
        """Get an access token using client credentials or password grant."""
        if self._token and self._token_expiry and datetime.utcnow() < self._token_expiry:
            return self._token

        token_url = f"{self.config.base_url}/realms/{self.config.realm}/protocol/openid-connect/token"
        payload: dict[str, str] = {"grant_type": "client_credentials"}
        
        if self.config.client_secret:
            payload["client_id"] = self.config.client_id
            payload["client_secret"] = self.config.client_secret
        else:
            payload["client_id"] = "admin-cli"
            payload["username"] = self.config.username
            payload["password"] = self.config.password
            payload["grant_type"] = "password"

        resp = httpx.post(
            token_url,
            data=payload,
            verify=self.config.verify_ssl,
            timeout=self.config.timeout,
        )
        resp.raise_for_status()
        data = resp.json()
        self._token = data["access_token"]
        expires_in = data.get("expires_in", 60)
        self._token_expiry = datetime.utcnow().replace(second=0, microsecond=0)
        self._token_expiry += timedelta(seconds=max(expires_in - 10, 10))
        return self._token

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self._get_token()}",
            "Content-Type": "application/json",
        }

    def _request(self, method: str, path: str, **kwargs) -> httpx.Response:
        url = f"{self._admin_url}{path}"
        resp = httpx.request(
            method,
            url,
            headers=self._headers(),
            verify=self.config.verify_ssl,
            timeout=self.config.timeout,
            **kwargs,
        )
        if resp.status_code >= 400:
            raise KeycloakClientError(
                f"Keycloak API error {method} {url}: {resp.status_code} {resp.text}"
            )
        return resp

    # --- User operations ---

    def get_user(self, user_id: str) -> dict[str, Any]:
        return self._request("GET", f"/users/{user_id}").json()

    def get_user_by_username(self, username: str) -> Optional[dict[str, Any]]:
        resp = self._request("GET", f"/users?username={username}&exact=true")
        users = resp.json()
        return users[0] if users else None

    def create_user(self, user_data: dict[str, Any]) -> str:
        resp = self._request("POST", "/users", json=user_data)
        location = resp.headers.get("Location", "")
        return location.rsplit("/", 1)[-1]

    def update_user(self, user_id: str, user_data: dict[str, Any]) -> None:
        self._request("PUT", f"/users/{user_id}", json=user_data)

    def disable_user(self, user_id: str) -> None:
        self._request("PUT", f"/users/{user_id}", json={"enabled": False})

    def enable_user(self, user_id: str) -> None:
        self._request("PUT", f"/users/{user_id}", json={"enabled": True})

    # --- Group operations ---

    def get_groups(self) -> list[dict[str, Any]]:
        return self._request("GET", "/groups").json()

    def get_group_by_name(self, group_name: str) -> Optional[dict[str, Any]]:
        groups = self._request("GET", f"/groups?search={group_name}").json()
        for g in groups:
            if g.get("name") == group_name:
                return g
        return None

    def list_user_groups(self, user_id: str) -> list[dict[str, Any]]:
        return self._request("GET", f"/users/{user_id}/groups").json()

    def assign_group(self, user_id: str, group_id: str) -> None:
        self._request("PUT", f"/users/{user_id}/groups/{group_id}")

    def remove_group(self, user_id: str, group_id: str) -> None:
        self._request("DELETE", f"/users/{user_id}/groups/{group_id}")

    def sync_user_groups(self, user_id: str, target_group_names: set[str]) -> dict[str, list[str]]:
        all_groups = {g["name"]: g["id"] for g in self.get_groups()}
        current_groups = {g["name"]: g["id"] for g in self.list_user_groups(user_id)}
        
        to_add = target_group_names - set(current_groups.keys())
        to_remove = set(current_groups.keys()) - target_group_names

        for group_name in to_add:
            if group_name in all_groups:
                self.assign_group(user_id, all_groups[group_name])
        
        for group_name in to_remove:
            if group_name in current_groups:
                self.remove_group(user_id, current_groups[group_name])

        return {"added": list(to_add), "removed": list(to_remove)}
