# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import Any, Optional
import httpx
from api.config.settings import get_settings
import logging

logger = logging.getLogger(__name__)


class ILIASClientError(Exception):
    """Exception raised for ILIAS API errors."""

    pass


class ILIASClient:
    """ILIAS REST API client.

    Implements ILIAS REST API with bearer token authentication.
    Falls back to mock data when no API URL/credentials are configured.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        api_user: Optional[str] = None,
        api_key: Optional[str] = None,
    ) -> None:
        settings = get_settings()
        self.base_url = base_url or settings.ilias_api_url
        self.api_user = api_user or settings.ilias_api_user
        self.api_key = api_key or settings.ilias_api_key
        self._client: Optional[httpx.AsyncClient] = None
        self._access_token: Optional[str] = None

    async def __aenter__(self) -> "ILIASClient":
        # If no external ILIAS base URL is configured in tests, provide a
        # harmless localhost base URL to avoid HTTP client initialization errors.
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
        return bool(self.base_url and self.api_user and self.api_key)

    async def _authenticate(self) -> None:
        """Authenticate with ILIAS API and get access token.

        ILIAS REST API authentication: POST /ilias.php/v1/auth
        with api_key and api_user in headers.
        """
        try:
            url = "/ilias.php/v1/auth"
            headers = {
                "Content-Type": "application/json",
                "X-ILIAS-API-Key": self.api_key,
                "X-ILIAS-API-User": self.api_user,
            }

            response = await self._client.post(url, json={}, headers=headers)
            response.raise_for_status()
            data = response.json()

            self._access_token = data.get("access_token")

            if not self._access_token:
                raise ILIASClientError("No access token returned from ILIAS API")

        except httpx.HTTPError as e:
            logger.error(f"HTTP error authenticating with ILIAS: {e}")
            raise ILIASClientError(f"Authentication failed: {e}")
        except Exception as e:
            logger.error(f"Error authenticating with ILIAS: {e}")
            raise ILIASClientError(f"Authentication failed: {e}")

    async def _api_call(
        self,
        endpoint: str,
        method: str = "GET",
        params: Optional[dict[str, Any]] = None,
        json_data: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any]:
        """Make an ILIAS REST API call.

        Args:
            endpoint: API endpoint path (e.g., /ilias.php/v1/courses)
            method: HTTP method (GET, POST, PUT, DELETE)
            params: Query parameters
            json_data: JSON request body

        Returns:
            Response data from ILIAS API

        Raises:
            ILIASClientError: If API call fails
        """
        if not self._is_configured():
            raise ILIASClientError("ILIAS API URL and credentials not configured")

        if not self._client:
            raise ILIASClientError("Client not initialized. Use async context manager.")

        headers = {
            "Content-Type": "application/json",
        }

        if self._access_token:
            headers["Authorization"] = f"Bearer {self._access_token}"

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
                raise ILIASClientError(f"Unsupported HTTP method: {method}")

            response.raise_for_status()
            return response.json()

        except httpx.HTTPError as e:
            logger.error(f"HTTP error calling ILIAS API: {e}")
            raise ILIASClientError(f"HTTP error: {e}")
        except Exception as e:
            logger.error(f"Error calling ILIAS API: {e}")
            raise ILIASClientError(f"API call failed: {e}")

    async def create_course(
        self, title: str, category_id: Optional[str] = None, **kwargs: Any
    ) -> dict[str, Any]:
        """Create a new ILIAS course.

        Args:
            title: Course title
            category_id: Course category ref ID
            **kwargs: Additional course fields

        Returns:
            Dictionary with course ID and status
        """
        if not self._is_configured():
            return {
                "ilias_course_id": f"ilias_{hash(title) % 10000}",
                "status": "created",
                "title": title,
            }

        endpoint = "/ilias.php/v1/courses"
        json_data = {"title": title}

        if category_id:
            json_data["category_id"] = category_id

        if "description" in kwargs:
            json_data["description"] = kwargs["description"]

        result = await self._api_call(endpoint, method="POST", json_data=json_data)

        return {
            "ilias_course_id": str(result.get("id", "")),
            "status": "created",
            "title": result.get("title", title),
        }

    async def get_course(self, course_id: str) -> dict[str, Any]:
        """Get an ILIAS course by ID.

        Args:
            course_id: ILIAS course ref ID

        Returns:
            Dictionary with course details
        """
        if not self._is_configured():
            return {
                "ilias_course_id": course_id,
                "status": "active",
                "title": "Stub Course",
            }

        endpoint = f"/ilias.php/v1/courses/{course_id}"
        result = await self._api_call(endpoint, method="GET")

        return {
            "ilias_course_id": result.get("id", course_id),
            "status": "active",
            "title": result.get("title", "Unknown Course"),
        }

    async def update_course(self, course_id: str, **kwargs: Any) -> dict[str, Any]:
        """Update an existing ILIAS course.

        Args:
            course_id: ILIAS course ref ID
            **kwargs: Fields to update

        Returns:
            Dictionary with updated course ID and status
        """
        if not self._is_configured():
            return {"ilias_course_id": course_id, "status": "updated"}

        endpoint = f"/ilias.php/v1/courses/{course_id}"
        json_data = {}

        if "title" in kwargs:
            json_data["title"] = kwargs["title"]
        if "description" in kwargs:
            json_data["description"] = kwargs["description"]

        await self._api_call(endpoint, method="PUT", json_data=json_data)

        return {"ilias_course_id": course_id, "status": "updated"}

    async def delete_course(self, course_id: str) -> dict[str, Any]:
        """Delete an ILIAS course.

        Args:
            course_id: ILIAS course ref ID

        Returns:
            Dictionary with deleted course ID and status
        """
        if not self._is_configured():
            return {"ilias_course_id": course_id, "status": "deleted"}

        endpoint = f"/ilias.php/v1/courses/{course_id}"
        await self._api_call(endpoint, method="DELETE")

        return {"ilias_course_id": course_id, "status": "deleted"}

    async def archive_course(self, course_id: str) -> dict[str, Any]:
        """Archive an ILIAS course (set offline).

        Args:
            course_id: ILIAS course ref ID

        Returns:
            Dictionary with course ID and new status
        """
        return await self.update_course(course_id, offline=True)

    async def enroll_user(
        self, course_id: str, user_id: str, role: str = "participant"
    ) -> dict[str, Any]:
        """Enroll a user in an ILIAS course.

        Args:
            course_id: ILIAS course ref ID
            user_id: ILIAS user ID
            role: Role (participant, tutor, admin)

        Returns:
            Dictionary with enrollment details
        """
        if not self._is_configured():
            return {
                "enrollment_id": f"enr_{hash(course_id + user_id) % 10000}",
                "course_id": course_id,
                "user_id": user_id,
                "role": role,
            }

        endpoint = f"/ilias.php/v1/courses/{course_id}/members/{user_id}"
        json_data = {"role": role}

        await self._api_call(endpoint, method="POST", json_data=json_data)

        return {
            "enrollment_id": f"enr_{hash(course_id + user_id) % 10000}",
            "course_id": course_id,
            "user_id": user_id,
            "role": role,
        }

    async def unenroll_user(self, course_id: str, user_id: str) -> dict[str, Any]:
        """Unenroll a user from an ILIAS course.

        Args:
            course_id: ILIAS course ref ID
            user_id: ILIAS user ID

        Returns:
            Dictionary with unenrollment status
        """
        if not self._is_configured():
            return {"status": "unenrolled", "course_id": course_id, "user_id": user_id}

        endpoint = f"/ilias.php/v1/courses/{course_id}/members/{user_id}"

        try:
            await self._api_call(endpoint, method="DELETE")
        except ILIASClientError:
            # Log but don't fail - user might not be enrolled
            logger.warning(f"Failed to unenroll user {user_id} from course {course_id}")

        return {"status": "unenrolled", "course_id": course_id, "user_id": user_id}

    async def health_check(self) -> bool:
        """Check if ILIAS API is accessible.

        Returns:
            True if API is healthy, False otherwise
        """
        if not self._is_configured():
            # No API configured, return True for mock mode
            return True

        try:
            # Try to get site info
            await self._api_call("/ilias.php/v1/courses", method="GET")
            return True
        except Exception as e:
            logger.warning(f"ILIAS health check failed: {e}")
            return False
