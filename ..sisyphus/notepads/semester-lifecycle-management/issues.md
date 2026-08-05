# F1 Code Review Findings — Critical Issues (REJECT)

## Summary

VERDICT: **REJECT** — Code has critical bugs that must to fixed before the code can be approved for production deployment.

## Critical Issues (Must fix before approval)

### 1. moodle_client.py - `_get_client()` creates new client on every call
- **CRITICAL** - Memory leak, resource exhaustion
- **File**: `api/utils/moodle_client.py`
- **Lines**: 62-74
- **Code**: `if self._client is None or `self._client = httpx.AsyncClient(...)`
        if self._client is None:
            self._client = httpx.AsyncClient(timeout=self.settings.moodle.timeout)
        return self._client

```
    - **Issue**: The `_get_client()` method should only new client on every call
        - **Critical**: Memory leak, resource exhaustion

        - **Fix**: Store client as singleton on the and with lazy initialization:
 in `__init__`:
```python
        if self._client is None:
            self._client = httpx.AsyncClient(
                base_url=self.settings.moodle.api_url,
                timeout=self.settings.moodle.timeout,
                headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
            )
        else:
            self._client = httpx.AsyncClient(...)

        return self._client

    - **Issue 2: moodle_client.py - `_get_token()` unreachable code
    **CRITICAL** - Dead code, unreachable error
    - **Line 86**: `if self._external_mode: return`
    # Line 87 is never executed, creates an
        # ...
        return
        # Dead code path
    - **Line 110**: `data = response.json()` - `data` is never defined but throws `MoodleAPIError`
    - **Issue 3**: moodle_client.py - `_request()` references undefined variables
    **CRITICAL** - Potential bugs
    - **Line 129**: `data = response.json()` - `data` may be be undefined and. It always used `response` (which contains exception info) when catching.
        - **Line 401**: `if response.status_code == 404:`
            return None
        # 200 OK - parse JSON response
        try:
            response.raise_for_status()
            data = response.json()
            self._token = data.get("token")
            return self._token
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                raise MoodleAPIError(f"Authentication failed: {e.response.text}")
            raise
        # Dead code path
        return None
    - **Issue 4**: moodle_client.py - `get_course()` and `get_enrollments()` use undefined `e` variable
    **CRITICAL** - Runtime errors
    - **Line 200**: `logger.warning(f"Failed to get course: {e}")  - Should have `{e}` instead of `e` for better context
    - **Line 410**: `logger.warning(f"Failed to get enrollments: {e}")  - uses `e` variable which is undefined in the context. Also check what exception is being logged.

 
        except HTTPStatusError as e:
            if e.response.status_code == 404:
                return None
        else:
            try:
                response = await client.get(...)
                if response.status_code == 404:
                    return None
                # Handle missing course
                return {}
            except httpx.HTTPError as e:
                logger.warning(f"Failed to get course: {e}")
                return None

        except httpx.HTTPError as e:
            logger.warning(f"Failed to get enrollments: {e}")
                return []

    - **Issue 5**: moodle_client.py - Missing error handling for 404 status
    **CRITICAL** - No error handling
    - **Line 127**: `if e.response.status_code == 404:`
                raise MoodleAPIError(f"Request failed: {e.response.text}")
            raise
        except httpx.HTTPError as e:
            raise MoodleAPIError(f"Request failed: {e.response.text}")

            raise

### Major Issues (Should Fix, But can defer)

### 1. main.py - LMS clients not closed on shutdown
    - **Lines**: 39-43: Lifespan cleanup
    - **Fix**: Call `ilias_client.close()`, `moodle_client.close()`, `keycloak_client.close()` in the lifespan context manager.
        - Ensure `async with` / async close for
    ```python
    async def close(self):
        if self._client:
            await self._client.aclose()
            self._client = None
```

    - **Impact**: Resource leaks, memory usage over time. Also prevents proper cleanup
```python
    # Only clear app.state, not cleanup app.state resources
        app.state.courses.clear()
        app.state.semesters.clear()
        app.state.enrollments.clear()
        app.state.archives.clear()

        app.state.ilias_client = None
        app.state.moodle_client = None
        app.state.keycloak_client = None

    - **Issue 2**: main.py - CORS defaults to `["*"]` allow all origins
    - **Fix**: Change to `["https://your-domain.com"]` for production or more restrictive list.
 Example: `["http://localhost:3000", "http://localhost:8080"]`.
        - **Current**: `["*"]`
        - **Recommendation**: Change to `["http://localhost:3000", "http://localhost:8080"]` for development only.
 Tighten in production.
            - Use `["https://opendesk-edu.example.com"]` for production
            - Only allow specific trusted domains
    - Consider environment-based allow list (e.g., `["http://localhost:3000", "http://localhost:8080"]` if `settings.api.cors_origins` is empty

 will be
        else:
            allowed_origins = `["*"]`.
            - **Impact**: Reduces security (all origins now allowed)
 but CORS has been.
            - Use environment variable `API_CORS_ALLOWED_ORIGINS` (e.g., `["http://localhost:3000", "http://localhost:8080"]`)
            - **Default**: Set `API_CORS_ALLOWED_ORIGins = from environment variable with comma-separated list
            - Example: `API_CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,api.opendesk-edu.com`
            - Set in `config.yaml`:
 override for production!

    - **File**: `scripts/semester-provisioning/config/config.yaml`

        - **Impact**: Existing config would be overridden (need to change)
        - **Recommendation**: Create separate config files per environment for easier management
            - Document process clearly

## Medium Priority Issues (Fix before approval, but nice to have)

### 1. routes/__init__.py - Corrupted content
    - **File**: `api/routes/__init__.py`
    - **Issue**: Contains incorrect content (imports models content)
    - **Impact**: Will cause confusion when importing the module
 Fix by replacing with correct content
```python
from .courses import router as courses_router
from .semesters import router as semesters_router
from .archival import router as archival_router
from .enrollments import router as enrollments_router
```
    - **File**: `api/routes/__init__.py`
    ```python
    from .courses import router as courses_router
    from .semesters import router as semesters_router
    from .archival import router as archival_router
    from .enrollments import router as enrollments_router
    from .courses import import (
        Course,
        CourseBase,
        CourseBulkCreate,
        CourseCreate,
        CourseListResponse,
        CourseStatus,
        CourseUpdate,
        LMSProvider,
    )
    from .semester import (
        Semester,
        SemesterCreate,
        SemesterListResponse,
        SemesterStatus,
    )
    from .enrollment import (
        Enrollment,
        EnrollmentCreate,
        EnrollmentBulkCreate,
        EnrollmentListResponse,
        EnrollmentRole,
        EnrollmentStatus,
    )
    from .archival import (
        ArchiveRequest,
        ArchiveResponse,
        ArchiveBulkRequest,
        ArchiveRestoreRequest,
    )
    from api.config.settings import get_settings
    from api.main import create_app
    from api.server import run