#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

"""
Keycloak client wrapper for role/group retrieval in the Semester Provisioning flow.

EN: Lightweight, testable interface to fetch roles and campus groups from Keycloak.
DE: Leichte, testbare Schnittstelle zum Abrufen von Rollen und Campus-Gruppen aus Keycloak.
"""

from typing import List, Optional
from pydantic import BaseModel


class KeycloakConfig(BaseModel):
    base_url: str
    realm: str
    token: str


class KeycloakRole(BaseModel):
    id: Optional[str] = None
    name: str


class KeycloakClient:
    """Wrapper around Keycloak REST API interactions.

    EN: Minimal client used by the synchronizer. In production, this would call
    the Keycloak REST endpoints. For tests, this class should be mocked or
    extended to provide deterministic data.
    DE: Minimaler Client für die Synchronisierung. In der Produktion würden hier
    die Keycloak REST-Endpunkte aufgerufen. Für Tests sollte diese Klasse gemockt
    oder erweitert werden, um deterministische Daten bereitzustellen.
    """

    def __init__(self, config: KeycloakConfig):
        self.config = config

    def get_roles(
        self,
    ) -> List[KeycloakRole]:  # pragma: no cover - to be mocked in tests
        """Fetch all roles from Keycloak realm.

        Returns:
            List of KeycloakRole objects with id and name fields.
        """
        # In production, this would make an HTTP request to Keycloak Admin API:
        # response = requests.get(
        #     f"{self.config.base_url}/admin/realms/{self.config.realm}/roles",
        #     headers={"Authorization": f"Bearer {self.config.token}"}
        # )
        # return [KeycloakRole(id=role["id"], name=role["name"]) for role in response.json()]
        # For now, return empty list - subclasses or test mocks should override
        return []

    def get_groups(self) -> List[str]:  # pragma: no cover - to be mocked in tests
        """Fetch all group names from Keycloak realm.

        Returns:
            List of group name strings.
        """
        # In production, this would make an HTTP request to Keycloak Admin API:
        # response = requests.get(
        #     f"{self.config.base_url}/admin/realms/{self.config.realm}/groups",
        #     headers={"Authorization": f"Bearer {self.config.token}"}
        # )
        # return [group["name"] for group in response.json()]
        # For now, return empty list - subclasses or test mocks should override
        return []
