# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import Any, Optional
import httpx
from api.config.settings import get_settings


class MoodleClientError(Exception):
    pass


class MoodleClient:
    def __init__(self, base_url: Optional[str] = None, api_token: Optional[str] = None):
        settings = get_settings()
        self.base_url = base_url or settings.moodle_api_url
        self.api_token = api_token or settings.moodle_api_token
        self._client: Optional[httpx.AsyncClient] = None

    async def __aenter__(self) -> "MoodleClient":
        self._client = httpx.AsyncClient(base_url=self.base_url, timeout=30.0)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        if self._client:
            await self._client.aclose()

    async def create_course(
        self, title: str, category_id: Optional[str] = None, **kwargs
    ) -> dict[str, Any]:
        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )
        return {
            "moodle_course_id": f"mdl_{hash(title) % 10000}",
            "status": "created",
            "fullname": title,
        }

    async def get_course(self, course_id: str) -> dict[str, Any]:
        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )
        return {
            "moodle_course_id": course_id,
            "status": "active",
            "fullname": "Stub Course",
        }

    async def update_course(self, course_id: str, **kwargs) -> dict[str, Any]:
        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )
        return {"moodle_course_id": course_id, "status": "updated"}

    async def delete_course(self, course_id: str) -> dict[str, Any]:
        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )
        return {"moodle_course_id": course_id, "status": "deleted"}

    async def archive_course(self, course_id: str) -> dict[str, Any]:
        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )
        return {"moodle_course_id": course_id, "status": "archived"}

    async def enroll_user(
        self, course_id: str, user_id: str, role: str = "student"
    ) -> dict[str, Any]:
        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )
        return {
            "enrollment_id": f"enr_{hash(course_id + user_id) % 10000}",
            "course_id": course_id,
            "user_id": user_id,
            "role": role,
        }

    async def unenroll_user(self, course_id: str, user_id: str) -> dict[str, Any]:
        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )
        return {"status": "unenrolled", "course_id": course_id, "user_id": user_id}

    async def health_check(self) -> bool:
        return True
