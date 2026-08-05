# Learnings

## 2026-02-13 Task 1: Test Infrastructure Setup

### Environment Constraints
- pip/pip3 is not available directly in this environment
- python3-venv package not installed
- Virtual environments cannot be created without apt install
- Workaround: Add pytest to both pyproject.toml AND requirements.txt

### Test Structure
- tests/ directory created at project root
- conftest.py uses `sys.path.insert(0, ...)` to add parent directory for imports
- Fixtures follow the existing Ucs class attribute patterns

### Key Fixtures Created
1. `mock_ucs` - MagicMock with all Ucs attributes pre-configured
2. `test_user_data` - Sample user dictionary
3. `mock_keycloak_response` - Token response mock
4. `mock_keycloak_user_response` - User lookup response mock
5. `non_reconcile_groups` - List of protected groups

### Python Import Pattern
```python
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
```
This allows importing `lib.*` modules in tests.

---

## 2026-02-13 Tasks 2-7: Complete Implementation

### New Methods Added to Ucs Class
1. `get_user_dn(username)` - Returns DN string
2. `get_user_groups(username)` - Returns list of group DNs
3. `disable_user(username, deprovision_timestamp)` - Sets disabled=true, updates description
4. `update_user_description(username, description)` - Updates description field
5. `remove_groups_except(username, keep_groups)` - Filters user groups

### Keycloak Module Pattern
- `lib/keycloak.py` contains functions for SAML identity management
- Uses requests library for HTTP calls
- Handles 204 (success) and 404 (already removed) responses
- Token acquisition uses POST to `/realms/master/protocol/openid-connect/token`

### Deprovision Scripts Structure
- Both scripts follow existing import script CLI pattern (configargparse)
- Logging setup matches existing `user_import_udm_rest_api.py` format
- Output files: `deprovisioned-{domain}-{timestamp}.txt` and `deleted-{domain}-{timestamp}.txt`

### Timestamp Format
- Project uses: `%Y-%m-%dT%Hh%Mm%SZ` (e.g., `2025-02-13T10h30m00sZ`)
- Must be consistent between write and read operations

### Environment Limitations
- pip/pytest not available in this environment
- Tests compile but cannot be executed
- API-based verification requires actual UCS/Keycloak access
