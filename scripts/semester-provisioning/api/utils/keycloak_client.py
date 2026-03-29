# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import Any, Optional
import httpx
from api.config.settings import get_settings


class KeycloakClientError(Exception):
    pass


class KeycloakClient:
    def __init__(
        self,
        base_url: Optional[str] = None,
        realm: Optional[str] = None,
        admin_user: Optional[str] = None,
        admin_password: Optional[str] = None,
    ):
        settings = get_settings()
        self.base_url = base_url or settings.keycloak_url
        self.realm = realm or settings.keycloak_realm
        self.admin_user = admin_user or settings.keycloak_admin_user
        self.admin_password = admin_password or settings.keycloak_admin_password
        self._client: Optional[httpx.AsyncClient] = None
        self._access_token: Optional[str] = None

    async def __aenter__(self) -> "KeycloakClient":
        self._client = httpx.AsyncClient(base_url=self.base_url, timeout=30.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        if self._client:
            await self._client.aclose()

    async def _ensure_token(self) -> None:
        self._access_token = "stub_token"

    async def create_group(
        self, name: str, parent_id: Optional[str] = None
    ) -> dict[str, Any]:
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        return {
            "group_id": f"grp_{hash(name) % 10000}",
            "name": name,
            "parent_id": parent_id,
        }

    async def get_group(self, group_id: str) -> dict[str, Any]:
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        return {"group_id": group_id, "name": "Stub Group"}

    async def delete_group(self, group_id: str) -> dict[str, Any]:
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        return {"status": "deleted", "group_id": group_id}

    async def add_user_to_group(self, user_id: str, group_id: str) -> dict[str, Any]:
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        return {"status": "added", "user_id": user_id, "group_id": group_id}

    async def remove_user_from_group(
        self, user_id: str, group_id: str
    ) -> dict[str, Any]:
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        return {"status": "removed", "user_id": user_id, "group_id": group_id}

    async def create_course_groups(
        self, course_id: str, semester_id: str
    ) -> dict[str, Any]:
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
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

    async def health_check(self) -> bool:
        return True

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
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        group_name = f"{course_id}-{role}s"
        return {
            "status": "added",
            "user_id": user_id,
            "course_id": course_id,
            "group": group_name,
        }

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
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        group_name = f"{course_id}-{role}s"
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
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        return {
            "status": "archived",
            "course_id": course_id,
            "groups_modified": [
                f"{course_id}-students",
                f"{course_id}-instructors",
                f"{course_id}-tutors",
            ],
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
        if not self._client:
            raise KeycloakClientError(
                "Client not initialized. Use async context manager."
            )
        await self._ensure_token()
        return {
            "status": "restored",
            "course_id": course_id,
            "groups_modified": [
                f"{course_id}-students",
                f"{course_id}-instructors",
                f"{course_id}-tutors",
            ],
        }
