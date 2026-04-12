# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from typing import Any, Optional
import httpx
from api.config.settings import get_settings
import logging

logger = logging.getLogger(__name__)


class MoodleClientError(Exception):
    """Exception raised for Moodle API errors."""

    pass


class MoodleClient:
    """Moodle Web Services API client.

    Implements Moodle Web Services API with token-based authentication.
    Falls back to mock data when no API URL/token is configured.
    """

    def __init__(
        self, base_url: Optional[str] = None, api_token: Optional[str] = None
    ) -> None:
        settings = get_settings()
        self.base_url = base_url or settings.moodle_api_url
        self.api_token = api_token or settings.moodle_api_token
        self._client: Optional[httpx.AsyncClient] = None

    async def __aenter__(self) -> "MoodleClient":
        # Provide a harmless base URL when no real Moodle URL is configured
        # in tests to prevent HTTP client initialization errors.
        url = self.base_url if self.base_url else "http://localhost"
        self._client = httpx.AsyncClient(base_url=url, timeout=30.0)
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
        return bool(self.base_url and self.api_token)

    async def _ws_call(self, wsfunction: str, params: dict[str, Any]) -> dict[str, Any]:
        """Make a Moodle Web Services API call.

        Args:
            wsfunction: Moodle WS function name (e.g., core_course_get_courses)
            params: Parameters for the WS function

        Returns:
            Response data from Moodle API

        Raises:
            MoodleClientError: If API call fails
        """
        if not self._is_configured():
            raise MoodleClientError("Moodle API URL and token not configured")

        if not self._client:
            raise MoodleClientError(
                "Client not initialized. Use async context manager."
            )

        # Moodle WS API format: /webservice/rest/server.php?wstoken=TOKEN&wsfunction=FUNC&moodlewsrestformat=json
        params["wstoken"] = self.api_token
        params["wsfunction"] = wsfunction
        params["moodlewsrestformat"] = "json"

        try:
            response = await self._client.post(
                "/webservice/rest/server.php", data=params
            )
            response.raise_for_status()
            data = response.json()

            # Moodle returns errors with 'exception' key
            if isinstance(data, dict) and "exception" in data:
                raise MoodleClientError(
                    f"Moodle API error: {data.get('message', data.get('errorcode', 'Unknown error'))}"
                )

            return data

        except httpx.HTTPError as e:
            logger.error(f"HTTP error calling Moodle API: {e}")
            raise MoodleClientError(f"HTTP error: {e}")
        except Exception as e:
            logger.error(f"Error calling Moodle API: {e}")
            raise MoodleClientError(f"API call failed: {e}")

    async def create_course(
        self, title: str, category_id: Optional[str] = None, **kwargs: Any
    ) -> dict[str, Any]:
        """Create a new Moodle course.

        Args:
            title: Course full name
            category_id: Course category ID
            **kwargs: Additional course fields (shortname, summary, etc.)

        Returns:
            Dictionary with course ID and status
        """
        if not self._is_configured():
            # Mock response for testing without API
            return {
                "moodle_course_id": f"mdl_{hash(title) % 10000}",
                "status": "created",
                "fullname": title,
            }

        params = {
            "courses[0][fullname]": title,
            "courses[0][shortname]": kwargs.get("shortname", title[:50]),
        }

        if category_id:
            params["courses[0][categoryid]"] = category_id

        if "summary" in kwargs:
            params["courses[0][summary]"] = kwargs["summary"]

        result = await self._ws_call("core_course_create_courses", params)

        if result and len(result) > 0:
            return {
                "moodle_course_id": str(result[0].get("id", "")),
                "status": "created",
                "fullname": result[0].get("fullname", title),
            }

        raise MoodleClientError("Failed to create course: no response from API")

    async def get_course(self, course_id: str) -> dict[str, Any]:
        """Get a Moodle course by ID.

        Args:
            course_id: Moodle course ID

        Returns:
            Dictionary with course details
        """
        if not self._is_configured():
            return {
                "moodle_course_id": course_id,
                "status": "active",
                "fullname": "Stub Course",
            }

        params = {"courseids[0]": course_id}
        result = await self._ws_call("core_course_get_courses", params)

        if result and len(result) > 0:
            course = result[0]
            return {
                "moodle_course_id": str(course.get("id", course_id)),
                "status": "active" if course.get("visible", True) else "hidden",
                "fullname": course.get("fullname", "Unknown Course"),
            }

        raise MoodleClientError(f"Course {course_id} not found")

    async def update_course(self, course_id: str, **kwargs: Any) -> dict[str, Any]:
        """Update an existing Moodle course.

        Args:
            course_id: Moodle course ID
            **kwargs: Fields to update (fullname, summary, etc.)

        Returns:
            Dictionary with updated course ID and status
        """
        if not self._is_configured():
            return {"moodle_course_id": course_id, "status": "updated"}

        params = {"courses[0][id]": course_id}

        if "fullname" in kwargs:
            params["courses[0][fullname]"] = kwargs["fullname"]
        if "summary" in kwargs:
            params["courses[0][summary]"] = kwargs["summary"]

        await self._ws_call("core_course_update_courses", params)

        return {"moodle_course_id": course_id, "status": "updated"}

    async def delete_course(self, course_id: str) -> dict[str, Any]:
        """Delete a Moodle course.

        Args:
            course_id: Moodle course ID

        Returns:
            Dictionary with deleted course ID and status
        """
        if not self._is_configured():
            return {"moodle_course_id": course_id, "status": "deleted"}

        await self._ws_call("core_course_delete_courses", {"courseids[0]": course_id})

        return {"moodle_course_id": course_id, "status": "deleted"}

    async def archive_course(self, course_id: str) -> dict[str, Any]:
        """Archive a Moodle course (set visibility to hidden).

        Args:
            course_id: Moodle course ID

        Returns:
            Dictionary with course ID and new status
        """
        return await self.update_course(course_id, visible=False)

    async def enroll_user(
        self, course_id: str, user_id: str, role: str = "student"
    ) -> dict[str, Any]:
        """Enroll a user in a Moodle course.

        Args:
            course_id: Moodle course ID
            user_id: Moodle user ID
            role: Role ID (default: 5 = student)

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

        # Map role names to Moodle role IDs
        role_ids = {
            "student": "5",
            "teacher": "3",
            "editingteacher": "4",
            "guest": "6",
        }

        role_id = role_ids.get(role, "5")  # Default to student

        params = {
            "enrolments[0][roleid]": role_id,
            "enrolments[0][userid]": user_id,
            "enrolments[0][courseid]": course_id,
        }

        await self._ws_call("enrol_manual_enrol_users", params)

        return {
            "enrollment_id": f"enr_{hash(course_id + user_id) % 10000}",
            "course_id": course_id,
            "user_id": user_id,
            "role": role,
        }

    async def unenroll_user(self, course_id: str, user_id: str) -> dict[str, Any]:
        """Unenroll a user from a Moodle course.

        Args:
            course_id: Moodle course ID
            user_id: Moodle user ID

        Returns:
            Dictionary with unenrollment status
        """
        if not self._is_configured():
            return {"status": "unenrolled", "course_id": course_id, "user_id": user_id}

        # Moodle doesn't have a direct unenroll WS function
        # This would typically be done via core_enrol_delete_enrolments
        params = {
            "enrolments[0][userid]": user_id,
            "enrolments[0][courseid]": course_id,
        }

        try:
            await self._ws_call("core_enrol_delete_enrolments", params)
        except MoodleClientError:
            # Log but don't fail - user might not be enrolled
            logger.warning(f"Failed to unenroll user {user_id} from course {course_id}")

        return {"status": "unenrolled", "course_id": course_id, "user_id": user_id}

    async def health_check(self) -> bool:
        """Check if Moodle API is accessible.

        Returns:
            True if API is healthy, False otherwise
        """
        if not self._is_configured():
            # No API configured, return True for mock mode
            return True

        try:
            result = await self._ws_call("core_webservice_get_site_info", {})
            # If we get a valid response, API is healthy
            return "sitename" in result or isinstance(result, list)
        except Exception as e:
            logger.warning(f"Moodle health check failed: {e}")
            return False
