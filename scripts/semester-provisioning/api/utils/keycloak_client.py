# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import Any, Optional
import httpx
from api.config.settings import get_settings
import logging

logger = logging.getLogger(__name__)


class KeycloakClientError(Exception):
    """Exception raised for Keycloak API errors."""

    pass


class KeycloakClient:
    """Keycloak Admin REST API client.

    Implements Keycloak Admin API with bearer token authentication.
    Falls back to mock data when no API URL/credentials are configured.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        realm: Optional[str] = None,
        admin_user: Optional[str] = None,
        admin_password: Optional[str] = None,
    ) -> None:
        settings = get_settings()
        self.base_url = base_url or settings.keycloak_url
        self.realm = realm or settings.keycloak_realm
        self.admin_user = admin_user or settings.keycloak_admin_user
        self.admin_password = admin_password or settings.keycloak_admin_password
        self.admin_client_id = settings.keycloak_client_id
        self._client: Optional[httpx.AsyncClient] = None
        self._access_token: Optional[str] = None

    async def __aenter__(self) -> "KeycloakClient":
        # Provide a harmless base URL when no real Keycloak URL is configured
        # in tests to prevent HTTP client initialization errors.
        url = self.base_url if self.base_url else "http://localhost"
        self._client = httpx.AsyncClient(base_url=url, timeout=30.0)

        # Authenticate if credentials are configured
        if self._is_configured():
            await self._authenticate()

        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: Any,
    ) -> None:
        if self._client:
            await self._client.aclose()

    def _is_configured(self) -> bool:
        """Check if API credentials are configured."""
        return bool(
            self.base_url and self.realm and self.admin_user and self.admin_password
        )

    async def _authenticate(self) -> None:
        """Authenticate with Keycloak and get admin access token.

        Uses OAuth2 client_credentials grant or password grant.
        """
        try:
            url = f"/realms/{self.realm}/protocol/openid-connect/token"
            data = {
                "grant_type": "password",
                "client_id": self.admin_client_id,
                "username": self.admin_user,
                "password": self.admin_password,
            }

            response = await self._client.post(url, data=data)
            response.raise_for_status()
            token_data = response.json()

            self._access_token = token_data.get("access_token")

            if not self._access_token:
                raise KeycloakClientError("No access token returned from Keycloak")

        except httpx.HTTPError as e:
            logger.error(f"HTTP error authenticating with Keycloak: {e}")
            raise KeycloakClientError(f"Authentication failed: {e}")
        except Exception as e:
            logger.error(f"Error authenticating with Keycloak: {e}")
            raise KeycloakClientError(f"Authentication failed: {e}")

    def _get_headers(self) -> dict[str, str]:
        """Get headers with authorization token.

        Returns:
            Headers dictionary with Authorization header
        """
        headers = {"Content-Type": "application/json"}

        if self._access_token:
            headers["Authorization"] = f"Bearer {self._access_token}"

        return headers

    async def _api_call(
        self,
        endpoint: str,
        method: str = "GET",
        params: Optional[dict[str, Any]] = None,
        json_data: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any]:
        """Make a Keycloak Admin API call.

        Args:
            endpoint: API endpoint path (e.g., /admin/realms/{realm}/groups)
            method: HTTP method (GET, POST, PUT, DELETE)
            params: Query parameters
            json_data: JSON request body

        Returns:
            Response data from Keycloak API

        Raises:
            KeycloakClientError: If API call fails
        """
        if not self._is_configured():
            raise KeycloakClientError("Keycloak API URL and credentials not configured")

        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )

        headers = self._get_headers()

        try:
            if method == "GET":
                response = await self._client.get(
                    endpoint, headers=headers, params=params
                )
            elif method == "POST":
                response = await self._client.post(
                    endpoint, headers=headers, params=params, json=json_data
                )
            elif method == "PUT":
                response = await self._client.put(
                    endpoint, headers=headers, params=params, json=json_data
                )
            elif method == "DELETE":
                response = await self._client.delete(
                    endpoint, headers=headers, params=params
                )
            else:
                raise KeycloakClientError(f"Unsupported HTTP method: {method}")

            # Some Keycloak APIs return 204 No Content
            if response.status_code == 204:
                return {}

            response.raise_for_status()
            return response.json()

        except httpx.HTTPError as e:
            logger.error(f"HTTP error calling Keycloak API: {e}")
            raise KeycloakClientError(f"HTTP error: {e}")
        except Exception as e:
            logger.error(f"Error calling Keycloak API: {e}")
            raise KeycloakClientError(f"API call failed: {e}")

    def _realm_endpoint(self, path: str) -> str:
        """Build a realm-specific endpoint URL.

        Args:
            path: API path (e.g., /groups)

        Returns:
            Full endpoint path for the configured realm
        """
        return f"/admin/realms/{self.realm}{path}"

    async def create_group(
        self, name: str, parent_id: Optional[str] = None
    ) -> dict[str, Any]:
        """Create a Keycloak group.

        Args:
            name: Group name
            parent_id: Parent group ID (optional)

        Returns:
            Dictionary with group ID and name
        """
        if not self._is_configured():
            return {
                "group_id": f"grp_{hash(name) % 10000}",
                "name": name,
                "parent_id": parent_id,
            }

        endpoint = self._realm_endpoint("/groups")
        json_data = {"name": name}

        if parent_id:
            # For nested groups, use the parent group's path
            json_data["path"] = f"{parent_id}/{name}"

        result = await self._api_call(endpoint, method="POST", json_data=json_data)

        return {
            "group_id": result.get("id", ""),
            "name": result.get("name", name),
            "parent_id": parent_id,
        }

    async def get_group(self, group_id: str) -> dict[str, Any]:
        """Get a Keycloak group by ID.

        Args:
            group_id: Group ID

        Returns:
            Dictionary with group details
        """
        if not self._is_configured():
            return {"group_id": group_id, "name": "Stub Group"}

        endpoint = self._realm_endpoint(f"/groups/{group_id}")
        result = await self._api_call(endpoint, method="GET")

        return {
            "group_id": result.get("id", group_id),
            "name": result.get("name", "Unknown Group"),
        }

    async def delete_group(self, group_id: str) -> dict[str, Any]:
        """Delete a Keycloak group.

        Args:
            group_id: Group ID

        Returns:
            Dictionary with deleted group ID and status
        """
        if not self._is_configured():
            return {"status": "deleted", "group_id": group_id}

        endpoint = self._realm_endpoint(f"/groups/{group_id}")
        await self._api_call(endpoint, method="DELETE")

        return {"status": "deleted", "group_id": group_id}

    async def add_user_to_group(self, user_id: str, group_id: str) -> dict[str, Any]:
        """Add a user to a Keycloak group.

        Args:
            user_id: User ID
            group_id: Group ID

        Returns:
            Dictionary with status and IDs
        """
        if not self._is_configured():
            return {"status": "added", "user_id": user_id, "group_id": group_id}

        endpoint = self._realm_endpoint(f"/users/{user_id}/groups/{group_id}")
        await self._api_call(endpoint, method="PUT")

        return {"status": "added", "user_id": user_id, "group_id": group_id}

    async def remove_user_from_group(
        self, user_id: str, group_id: str
    ) -> dict[str, Any]:
        """Remove a user from a Keycloak group.

        Args:
            user_id: User ID
            group_id: Group ID

        Returns:
            Dictionary with status and IDs
        """
        if not self._is_configured():
            return {"status": "removed", "user_id": user_id, "group_id": group_id}

        endpoint = self._realm_endpoint(f"/users/{user_id}/groups/{group_id}")
        await self._api_call(endpoint, method="DELETE")

        return {"status": "removed", "user_id": user_id, "group_id": group_id}

    async def create_course_groups(
        self, course_id: str, semester_id: str
    ) -> dict[str, Any]:
        """Create course-specific groups (students, instructors).

        Args:
            course_id: Course identifier
            semester_id: Semester identifier

        Returns:
            Dictionary with students and instructors group details
        """
        if not self._is_configured():
            students_group = await self.create_group(
                f"{course_id}-students", parent_id=f"semesters/{semester_id}/courses"
            )
            instructors_group = await self.create_group(
                f"{course_id}-instructors", parent_id=f"semesters/{semester_id}/courses"
            )
            return {
                "students_group": students_group,
                "instructors_group": instructors_group,
            }

        students_group = await self.create_group(
            f"{course_id}-students", parent_id=semester_id
        )
        instructors_group = await self.create_group(
            f"{course_id}-instructors", parent_id=semester_id
        )

        return {
            "students_group": students_group,
            "instructors_group": instructors_group,
        }

    async def health_check(self) -> bool:
        """Check if Keycloak API is accessible.

        Returns:
            True if API is healthy, False otherwise
        """
        if not self._is_configured():
            # No API configured, return True for mock mode
            return True

        try:
            # Try to get realm info
            endpoint = self._realm_endpoint("/")
            await self._api_call(endpoint, method="GET")
            return True
        except Exception as e:
            logger.warning(f"Keycloak health check failed: {e}")
            return False

    async def add_user_to_course_group(
        self, course_id: str, user_id: str, role: str
    ) -> dict[str, Any]:
        """
        Add a user to a course-specific role group.
        Fügt einen Benutzer zu einer kursspezifischen Rollengruppe hinzu.

        Args:
            course_id: Course identifier / Kurskennung
            user_id: User identifier / Benutzerkennung
            role: Role (student, instructor, tutor) / Rolle

        Returns:
            Result dict with status / Ergebnisdikt mit Status
        """
        if not self._is_configured():
            return {
                "status": "added",
                "user_id": user_id,
                "course_id": course_id,
                "group": f"{course_id}-{role}s",
            }

        group_name = f"{course_id}-{role}s"
        # First, get the group ID by searching for it
        groups = await self._api_call(
            self._realm_endpoint("/groups"), method="GET", params={"search": group_name}
        )

        if groups and len(groups) > 0:
            group_id = groups[0].get("id")
            await self.add_user_to_group(user_id, group_id)
            return {
                "status": "added",
                "user_id": user_id,
                "course_id": course_id,
                "group": group_name,
            }

        raise KeycloakClientError(f"Role group {group_name} not found")

    async def remove_user_from_course_group(
        self, course_id: str, user_id: str, role: str
    ) -> dict[str, Any]:
        """
        Remove a user from a course-specific role group.
        Entfernt einen Benutzer aus einer kursspezifischen Rollengruppe.

        Args:
            course_id: Course identifier / Kurskennung
            user_id: User identifier / Benutzerkennung
            role: Role (student, instructor, tutor) / Rolle

        Returns:
            Result dict with status / Ergebnisdikt mit Status
        """
        if not self._is_configured():
            return {
                "status": "removed",
                "user_id": user_id,
                "course_id": course_id,
                "group": f"{course_id}-{role}s",
            }

        group_name = f"{course_id}-{role}s"
        groups = await self._api_call(
            self._realm_endpoint("/groups"), method="GET", params={"search": group_name}
        )

        if groups and len(groups) > 0:
            group_id = groups[0].get("id")
            await self.remove_user_from_group(user_id, group_id)
            return {
                "status": "removed",
                "user_id": user_id,
                "course_id": course_id,
                "group": group_name,
            }

        return {
            "status": "removed",
            "user_id": user_id,
            "course_id": course_id,
            "group": group_name,
        }

    async def archive_course_groups(self, course_id: str) -> dict[str, Any]:
        """
        Archive course groups (add archived tag, restrict access).
        Archiviert Kursgruppen (fügt Archiv-Tag hinzu, beschränkt Zugriff).

        Args:
            course_id: Course identifier / Kurskennung

        Returns:
            Result dict with status / Ergebnisdikt mit Status
        """
        if not self._is_configured():
            return {
                "status": "archived",
                "course_id": course_id,
                "groups_modified": [
                    f"{course_id}-students",
                    f"{course_id}-instructors",
                    f"{course_id}-tutors",
                ],
            }

        # In a real implementation, we would:
        # 1. Find all course groups
        # 2. Add an attribute or rename to indicate archived status
        # 3. Possibly remove all users from the groups

        groups_modified = []
        for role in ["students", "instructors", "tutors"]:
            group_name = f"{course_id}-{role}"
            try:
                groups = await self._api_call(
                    self._realm_endpoint("/groups"),
                    method="GET",
                    params={"search": group_name},
                )
                if groups:
                    # Add attributes to mark as archived
                    group_id = groups[0].get("id")
                    await self._api_call(
                        self._realm_endpoint(f"/groups/{group_id}"),
                        method="PUT",
                        json_data={"attributes": {"archived": ["true"]}},
                    )
                    groups_modified.append(group_name)
            except Exception as e:
                logger.warning(f"Failed to archive group {group_name}: {e}")

        return {
            "status": "archived",
            "course_id": course_id,
            "groups_modified": groups_modified,
        }

    async def restore_course_groups(self, course_id: str) -> dict[str, Any]:
        """
        Restore archived course groups to active status.
        Stellt archivierte Kursgruppen in den aktiven Status zurück.

        Args:
            course_id: Course identifier / Kurskennung

        Returns:
            Result dict with status / Ergebnisdikt mit Status
        """
        if not self._is_configured():
            return {
                "status": "restored",
                "course_id": course_id,
                "groups_modified": [
                    f"{course_id}-students",
                    f"{course_id}-instructors",
                    f"{course_id}-tutors",
                ],
            }

        groups_modified = []
        for role in ["students", "instructors", "tutors"]:
            group_name = f"{course_id}-{role}"
            try:
                groups = await self._api_call(
                    self._realm_endpoint("/groups"),
                    method="GET",
                    params={"search": group_name},
                )
                if groups:
                    group_id = groups[0].get("id")
                    await self._api_call(
                        self._realm_endpoint(f"/groups/{group_id}"),
                        method="PUT",
                        json_data={"attributes": {"archived": ["false"]}},
                    )
                    groups_modified.append(group_name)
            except Exception as e:
                logger.warning(f"Failed to restore group {group_name}: {e}")

        return {
            "status": "restored",
            "course_id": course_id,
            "groups_modified": groups_modified,
        }
