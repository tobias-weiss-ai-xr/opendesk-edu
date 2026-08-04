# User Import + SAML Lifecycle Integration Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Incorporate a cleaned version of the `user_import` tooling into `opendesk-edu/scripts/user_import/` with configurable SAML account linking, provisioning, and deprovisioning for external Shibboleth IdP integration.

**Architecture:** Move the core Python tooling (provisioning, deprovisioning, SAML linking) from `user_import/` into `opendesk-edu/scripts/user_import/`. Clean up hardcoded URLs/credentials, deduplicate constants, merge standalone scripts into the lib module, and make the SAML provider alias configurable. The tooling sits alongside existing `scripts/federation/` and `scripts/semester/` as operational tooling (not a Helm chart).

**Tech Stack:** Python 3.12, `requests`, `configargparse`, `pandas`, Keycloak Admin REST API, Univention UDM REST API

---

## File Structure

```
opendesk-edu/scripts/user_import/
├── README.md              # Usage guide, deployment, configuration reference
├── pyproject.toml         # Package config, dependencies, entry points
├── requirements.txt       # Pinned runtime dependencies
├── Dockerfile             # Alpine-based container for k8s cronjob deployment
├── lib/
│   ├── __init__.py        # Package init, version
│   ├── ucs.py             # UDM REST API client (cleaned from user_import/lib/ucs.py)
│   ├── keycloak.py        # SAML identity management (link + remove, configurable provider alias)
│   ├── import_user.py     # User import class (uses lib/keycloak for SAML, configurable IAM URL)
│   ├── random_user.py     # Random user generator for testing
│   ├── argparse_types.py  # CLI utility (opt2bool)
│   └── constants.py       # Shared constants (NON_RECONCILE_GROUPS, defaults)
├── provision.py           # Main entry point: import users + link SAML identities
├── deprovision_disable.py # Phase 1: disable + unlink SAML + remove groups
├── deprovision_delete.py  # Phase 2: permanent delete after grace period
└── tests/
    ├── __init__.py
    ├── conftest.py        # Shared fixtures
    ├── test_keycloak.py   # Keycloak SAML module tests
    └── test_ucs.py        # UDM API client tests
```

**Source files (read-only references):**

- `user_import/lib/ucs.py` — 627 lines, the UDM REST API client
- `user_import/lib/keycloak.py` — 160 lines, SAML identity removal
- `user_import/lib/import_user.py` — 161 lines, user import with inline SAML linking
- `user_import/lib/random_user.py` — 87 lines, random user generator
- `user_import/lib/argparse_types.py` — 14 lines, opt2bool utility
- `user_import/user_import_udm_rest_api.py` — 349 lines, main entry point
- `user_import/deprovision_disable.py` — 440 lines, phase 1 deprovision
- `user_import/deprovision_delete.py` — 385 lines, phase 2 deprovision
- `user_import/tests/conftest.py` — 83 lines, test fixtures
- `user_import/tests/test_keycloak.py` — 182 lines, Keycloak tests
- `user_import/tests/test_ucs.py` — 98 lines, UDM tests (mostly stubs)

**DO NOT move (sensitive/generated data):**

- `user_import/template.csv`, `user_import/template.ods` — real user data
- `user_import/all-hrz-users-*` — real LDAP data
- `user_import/users-*.txt` — generated credentials
- `user_import/keycloak-logs.log` — debug logs
- `user_import/DEPLOYMENT.md` — contains plaintext passwords
- `user_import/data/images_*` — large binary assets
- `user_import/link_users.py` — prototype with hardcoded creds (logic merged into lib/keycloak.py)
- `user_import/scripts/convert_user_json_to_xlsx.py` — one-off conversion script

---

## Chunk 1: Foundation — lib module + constants

### Task 1: Create package structure and shared constants

**Files:**

- Create: `opendesk-edu/scripts/user_import/lib/__init__.py`
- Create: `opendesk-edu/scripts/user_import/lib/constants.py`

- [ ] **Step 1: Create `lib/__init__.py`**

```python
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

"""User import and lifecycle management tools for openDesk Edu."""

__version__ = "1.0.0"
```

- [ ] **Step 2: Create `lib/constants.py`**

```python
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

"""
Shared constants for user import tooling.

These are the groups that should never be removed during group reconciliation
or deprovisioning. They are system-managed groups in the openDesk UCS/LDAP.
"""

DEFAULT_REALM = "opendesk"
DEFAULT_KEYCLOAK_MASTER_REALM = "master"

DEFAULT_IDENTITY_PROVIDER = "saml-umr"

# Groups managed by the openDesk platform — never remove these from users
NON_RECONCILE_GROUPS = [
    "cn=Domain Admins,cn=groups,dc=swp-ldap,dc=internal",
    "cn=Domain Users,cn=groups,dc=swp-ldap,dc=internal",
    "cn=IAM API - Full Access,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Fileshare,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-FileshareAdmin,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Groupware,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Knowledgemanagement,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-KnowledgemanagementAdmin,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Livecollaboration,cn=groups,dc=swp-ldap,dc=internal",
    "cn=managed-by-attribute-Projectmanagement,cn=groups,dc=swp-ldap,dc=internal",
]
```

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/
git commit -m "feat(user-import): create package structure and shared constants"
```

### Task 2: Create cleaned `lib/keycloak.py` with SAML link + remove

**Files:**

- Create: `opendesk-edu/scripts/user_import/lib/keycloak.py`
- Test: `opendesk-edu/scripts/user_import/tests/test_keycloak.py`

- [ ] **Step 1: Write tests for `lib/keycloak.py`**

```python
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

"""Tests for Keycloak SAML identity management module."""

import pytest
import requests
from unittest.mock import patch, MagicMock
from lib.keycloak import (
    get_keycloak_token,
    get_keycloak_user_id,
    link_saml_identity,
    remove_saml_identity,
    remove_saml_identity_with_credentials,
    link_saml_identity_with_credentials,
)


@pytest.fixture
def mock_token():
    return "test-access-token-abc123"


@pytest.fixture
def mock_user_id():
    return "550e8400-e29b-41d4-a716-446655440000"


@pytest.fixture
def keycloak_url():
    return "https://id.example.com"


@pytest.fixture
def identity_provider():
    return "saml-umr"


class TestGetKeycloakToken:
    def test_returns_token_on_success(self, keycloak_url, mock_token):
        with patch("lib.keycloak.requests.post") as mock_post:
            mock_post.return_value = MagicMock(
                status_code=200,
                json=lambda: {"access_token": mock_token},
                raise_for_status=MagicMock(),
            )
            token = get_keycloak_token(keycloak_url, "admin", "secret")
            assert token == mock_token

    def test_returns_none_on_auth_failure(self, keycloak_url):
        with patch("lib.keycloak.requests.post") as mock_post:
            mock_post.return_value = MagicMock(
                status_code=401,
                json=lambda: {"error": "invalid_grant"},
                raise_for_status=MagicMock(side_effect=requests.exceptions.HTTPError("401")),
            )
            token = get_keycloak_token(keycloak_url, "admin", "wrong")
            assert token is None

    def test_returns_none_on_connection_error(self, keycloak_url):
        with patch("lib.keycloak.requests.post") as mock_post:
            mock_post.side_effect = requests.exceptions.ConnectionError("refused")
            token = get_keycloak_token(keycloak_url, "admin", "secret")
            assert token is None

    def test_uses_custom_realm(self, keycloak_url, mock_token):
        with patch("lib.keycloak.requests.post") as mock_post:
            mock_post.return_value = MagicMock(
                status_code=200,
                json=lambda: {"access_token": mock_token},
                raise_for_status=MagicMock(),
            )
            get_keycloak_token(keycloak_url, "admin", "secret", realm="custom")
            mock_post.assert_called_once()
            url = mock_post.call_args[0][0]
            assert "/realms/custom/" in url


class TestGetKeycloakUserId:
    def test_returns_user_id_on_found(self, keycloak_url, mock_token, mock_user_id):
        with patch("lib.keycloak.requests.get") as mock_get:
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [{"id": mock_user_id, "username": "testuser"}],
                raise_for_status=MagicMock(),
            )
            uid = get_keycloak_user_id(keycloak_url, "testuser", mock_token)
            assert uid == mock_user_id

    def test_returns_none_on_not_found(self, keycloak_url, mock_token):
        with patch("lib.keycloak.requests.get") as mock_get:
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [],
                raise_for_status=MagicMock(),
            )
            uid = get_keycloak_user_id(keycloak_url, "nonexistent", mock_token)
            assert uid is None

    def test_returns_none_on_error(self, keycloak_url, mock_token):
        with patch("lib.keycloak.requests.get") as mock_get:
            mock_get.side_effect = requests.exceptions.ConnectionError("refused")
            uid = get_keycloak_user_id(keycloak_url, "testuser", mock_token)
            assert uid is None


class TestLinkSamlIdentity:
    def test_links_identity_success(self, keycloak_url, mock_token, mock_user_id, identity_provider):
        with (
            patch("lib.keycloak.requests.get") as mock_get,
            patch("lib.keycloak.requests.post") as mock_post,
        ):
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [{"id": mock_user_id, "username": "testuser"}],
                raise_for_status=MagicMock(),
            )
            mock_post.return_value = MagicMock(
                status_code=204,
                raise_for_status=MagicMock(),
            )
            result = link_saml_identity(
                keycloak_url, "testuser", mock_token,
                identity_provider=identity_provider,
                user_id_attribute="username",
            )
            assert result is True

    def test_returns_false_on_post_failure(self, keycloak_url, mock_token, mock_user_id, identity_provider):
        with (
            patch("lib.keycloak.requests.get") as mock_get,
            patch("lib.keycloak.requests.post") as mock_post,
        ):
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [{"id": mock_user_id, "username": "testuser"}],
                raise_for_status=MagicMock(),
            )
            mock_post.return_value = MagicMock(
                status_code=500,
                text="Internal Server Error",
                raise_for_status=MagicMock(side_effect=requests.exceptions.HTTPError("500")),
            )
            result = link_saml_identity(
                keycloak_url, "testuser", mock_token,
                identity_provider=identity_provider,
            )
            assert result is False


class TestRemoveSamlIdentity:
    def test_removes_identity_success(self, keycloak_url, mock_token, mock_user_id, identity_provider):
        with (
            patch("lib.keycloak.requests.get") as mock_get,
            patch("lib.keycloak.requests.delete") as mock_delete,
        ):
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [{"id": mock_user_id, "username": "testuser"}],
                raise_for_status=MagicMock(),
            )
            mock_delete.return_value = MagicMock(status_code=204)
            result = remove_saml_identity(keycloak_url, "testuser", mock_token, identity_provider=identity_provider)
            assert result is True

    def test_already_removed_is_success(self, keycloak_url, mock_token, mock_user_id, identity_provider):
        with (
            patch("lib.keycloak.requests.get") as mock_get,
            patch("lib.keycloak.requests.delete") as mock_delete,
        ):
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [{"id": mock_user_id, "username": "testuser"}],
                raise_for_status=MagicMock(),
            )
            mock_delete.return_value = MagicMock(status_code=404)
            result = remove_saml_identity(keycloak_url, "testuser", mock_token, identity_provider=identity_provider)
            assert result is True

    def test_returns_false_on_user_not_found(self, keycloak_url, mock_token, identity_provider):
        with patch("lib.keycloak.requests.get") as mock_get:
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [],
                raise_for_status=MagicMock(),
            )
            result = remove_saml_identity(keycloak_url, "nonexistent", mock_token, identity_provider=identity_provider)
            assert result is False


class TestConvenienceFunctions:
    def test_remove_with_credentials(self, keycloak_url, mock_token, mock_user_id, identity_provider):
        with (
            patch("lib.keycloak.requests.post") as mock_post,
            patch("lib.keycloak.requests.get") as mock_get,
            patch("lib.keycloak.requests.delete") as mock_delete,
        ):
            mock_post.return_value = MagicMock(
                status_code=200,
                json=lambda: {"access_token": mock_token},
                raise_for_status=MagicMock(),
            )
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [{"id": mock_user_id, "username": "testuser"}],
                raise_for_status=MagicMock(),
            )
            mock_delete.return_value = MagicMock(status_code=204)
            result = remove_saml_identity_with_credentials(
                keycloak_url, "testuser", "admin", "secret",
                identity_provider=identity_provider,
            )
            assert result is True

    def test_link_with_credentials(self, keycloak_url, mock_token, mock_user_id, identity_provider):
        with (
            patch("lib.keycloak.requests.post") as mock_post,
            patch("lib.keycloak.requests.get") as mock_get,
        ):
            mock_post.return_value = MagicMock(
                status_code=200,
                json=lambda: {"access_token": mock_token},
                raise_for_status=MagicMock(),
            )
            mock_get.return_value = MagicMock(
                status_code=200,
                json=lambda: [{"id": mock_user_id, "username": "testuser"}],
                raise_for_status=MagicMock(),
            )
            result = link_saml_identity_with_credentials(
                keycloak_url, "testuser", "admin", "secret",
                identity_provider=identity_provider,
            )
            assert result is True
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd opendesk-edu/scripts/user_import && python -m pytest tests/test_keycloak.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'lib.keycloak'`

- [ ] **Step 3: Create `lib/keycloak.py`**

```python
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

"""
Keycloak SAML identity management module.

Provides functions to manage SAML federated identities in Keycloak —
both linking (provisioning) and removing (deprovisioning).

All functions accept an `identity_provider` parameter so the SAML IdP alias
is configurable (e.g., "saml-umr", "dfn-aai", "sso-federation-idp").
"""

import requests
import logging
from typing import Optional

from lib.constants import DEFAULT_REALM, DEFAULT_KEYCLOAK_MASTER_REALM, DEFAULT_IDENTITY_PROVIDER


def get_keycloak_token(
    keycloak_url: str,
    username: str,
    password: str,
    realm: str = DEFAULT_KEYCLOAK_MASTER_REALM,
) -> Optional[str]:
    """
    Get an access token from Keycloak using username/password.

    Args:
        keycloak_url: Base URL of Keycloak (e.g., "https://id.example.com")
        username: Keycloak admin username
        password: Keycloak admin password
        realm: Realm to authenticate against (default: master)

    Returns:
        Access token string or None if authentication failed
    """
    token_url = f"{keycloak_url}/realms/{realm}/protocol/openid-connect/token"

    try:
        response = requests.post(
            token_url,
            data={
                "client_id": "admin-cli",
                "username": username,
                "password": password,
                "grant_type": "password",
            },
        )
        response.raise_for_status()
        return response.json()["access_token"]
    except requests.RequestException as e:
        logging.error(f"Failed to get Keycloak token: {e}")
        return None


def get_keycloak_user_id(
    keycloak_url: str,
    username: str,
    access_token: str,
    realm: str = DEFAULT_REALM,
) -> Optional[str]:
    """
    Look up a user's ID by username in Keycloak.

    Args:
        keycloak_url: Base URL of Keycloak
        username: Username to look up
        access_token: Valid admin access token
        realm: Realm to search (default: opendesk)

    Returns:
        User ID string or None if not found
    """
    lookup_url = f"{keycloak_url}/admin/realms/{realm}/users"
    headers = {"Authorization": f"Bearer {access_token}"}

    try:
        response = requests.get(
            lookup_url,
            headers=headers,
            params={"username": username},
        )
        response.raise_for_status()
        users = response.json()
        if users and len(users) > 0:
            return users[0]["id"]
        logging.warning(f"User {username} not found in Keycloak realm {realm}")
        return None
    except requests.RequestException as e:
        logging.error(f"Failed to lookup Keycloak user {username}: {e}")
        return None


def link_saml_identity(
    keycloak_url: str,
    username: str,
    access_token: str,
    realm: str = DEFAULT_REALM,
    identity_provider: str = DEFAULT_IDENTITY_PROVIDER,
    user_id_attribute: str = "username",
) -> bool:
    """
    Link a Keycloak user to a SAML federated identity provider.

    This is used during provisioning to associate a local Keycloak user
    with an external SAML IdP (e.g., a university's Shibboleth IdP).

    Args:
        keycloak_url: Base URL of Keycloak
        username: Username to link
        access_token: Valid admin access token
        realm: Realm (default: opendesk)
        identity_provider: SAML IdP alias in Keycloak (default: saml-umr)
        user_id_attribute: Which Keycloak user attribute to use as the
            federated identity userId (default: username)

    Returns:
        True if successful, False on error
    """
    user_id = get_keycloak_user_id(keycloak_url, username, access_token, realm)
    if not user_id:
        logging.warning(f"User {username} not found in Keycloak, cannot link SAML identity")
        return False

    link_url = f"{keycloak_url}/admin/realms/{realm}/users/{user_id}/federated-identity/{identity_provider}"
    headers = {"Authorization": f"Bearer {access_token}"}

    payload = {
        "userId": username,
        "userName": username,
    }

    try:
        response = requests.post(link_url, headers=headers, json=payload)

        if response.status_code in (204, 200):
            logging.info(f"SAML identity linked for user {username} to provider {identity_provider}")
            return True
        elif response.status_code == 409:
            logging.info(f"SAML identity already linked for user {username}")
            return True
        else:
            logging.warning(
                f"Unexpected status {response.status_code} linking SAML for {username}: {response.text}"
            )
            return False

    except requests.RequestException as e:
        logging.error(f"Failed to link SAML identity for {username}: {e}")
        return False


def remove_saml_identity(
    keycloak_url: str,
    username: str,
    access_token: str,
    realm: str = DEFAULT_REALM,
    identity_provider: str = DEFAULT_IDENTITY_PROVIDER,
) -> bool:
    """
    Remove SAML federated identity from a Keycloak user.

    Args:
        keycloak_url: Base URL of Keycloak
        username: Username to remove SAML from
        access_token: Valid admin access token
        realm: Realm (default: opendesk)
        identity_provider: Identity provider name (default: saml-umr)

    Returns:
        True if successful (including already removed), False on error
    """
    user_id = get_keycloak_user_id(keycloak_url, username, access_token, realm)
    if not user_id:
        logging.warning(f"User {username} not found in Keycloak, cannot remove SAML identity")
        return False

    delete_url = f"{keycloak_url}/admin/realms/{realm}/users/{user_id}/federated-identity/{identity_provider}"
    headers = {"Authorization": f"Bearer {access_token}"}

    try:
        response = requests.delete(delete_url, headers=headers)

        if response.status_code == 204:
            logging.info(f"SAML identity removed for user {username}")
            return True
        elif response.status_code == 404:
            logging.info(f"SAML identity already removed for user {username}")
            return True
        else:
            logging.warning(f"Unexpected status {response.status_code} removing SAML for {username}")
            return False

    except requests.RequestException as e:
        logging.error(f"Failed to remove SAML identity for {username}: {e}")
        return False


def remove_saml_identity_with_credentials(
    keycloak_url: str,
    username: str,
    admin_username: str,
    admin_password: str,
    realm: str = DEFAULT_REALM,
    identity_provider: str = DEFAULT_IDENTITY_PROVIDER,
) -> bool:
    """
    Convenience: remove SAML identity using admin credentials (token + removal in one call).

    Args:
        keycloak_url: Base URL of Keycloak
        username: Username to remove SAML from
        admin_username: Keycloak admin username
        admin_password: Keycloak admin password
        realm: Realm (default: opendesk)
        identity_provider: Identity provider name (default: saml-umr)

    Returns:
        True if successful, False on error
    """
    access_token = get_keycloak_token(keycloak_url, admin_username, admin_password)
    if not access_token:
        logging.error("Failed to authenticate with Keycloak")
        return False

    return remove_saml_identity(keycloak_url, username, access_token, realm, identity_provider)


def link_saml_identity_with_credentials(
    keycloak_url: str,
    username: str,
    admin_username: str,
    admin_password: str,
    realm: str = DEFAULT_REALM,
    identity_provider: str = DEFAULT_IDENTITY_PROVIDER,
    user_id_attribute: str = "username",
) -> bool:
    """
    Convenience: link SAML identity using admin credentials (token + link in one call).

    Args:
        keycloak_url: Base URL of Keycloak
        username: Username to link
        admin_username: Keycloak admin username
        admin_password: Keycloak admin password
        realm: Realm (default: opendesk)
        identity_provider: SAML IdP alias (default: saml-umr)
        user_id_attribute: Which attribute to use as federated userId

    Returns:
        True if successful, False on error
    """
    access_token = get_keycloak_token(keycloak_url, admin_username, admin_password)
    if not access_token:
        logging.error("Failed to authenticate with Keycloak")
        return False

    return link_saml_identity(
        keycloak_url, username, access_token, realm, identity_provider, user_id_attribute
    )
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd opendesk-edu/scripts/user_import && python -m pytest tests/test_keycloak.py -v`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add opendesk-edu/scripts/user_import/lib/keycloak.py opendesk-edu/scripts/user_import/tests/test_keycloak.py
git commit -m "feat(user-import): add Keycloak SAML identity management module with tests"
```

### Task 3: Copy and clean `lib/ucs.py`

**Files:**

- Create: `opendesk-edu/scripts/user_import/lib/ucs.py`
- Reference: `user_import/lib/ucs.py` (627 lines, copy source)

- [ ] **Step 1: Copy ucs.py from user_import**

Copy `user_import/lib/ucs.py` to `opendesk-edu/scripts/user_import/lib/ucs.py` with these changes:

1. Update SPDX headers (keep dual copyright)
2. Import `NON_RECONCILE_GROUPS` from `lib.constants` instead of defining locally (it's not defined there currently but the import scripts reference it — verify this)
3. Ensure no hardcoded URLs or credentials remain
4. Keep the existing code structure and class API intact

**Key rule:** Do NOT refactor the Ucs class API — the existing scripts depend on it. Only update imports and headers.

- [ ] **Step 2: Verify imports resolve**

Run: `cd opendesk-edu/scripts/user_import && python -c "from lib.ucs import Ucs; print('OK')"`
Expected: OK

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/lib/ucs.py
git commit -m "feat(user-import): add UDM REST API client library"
```

### Task 4: Copy and clean `lib/import_user.py`

**Files:**

- Create: `opendesk-edu/scripts/user_import/lib/import_user.py`
- Reference: `user_import/lib/import_user.py` (161 lines)

- [ ] **Step 1: Rewrite `lib/import_user.py`**

The original has hardcoded IAM API URL and inline SAML linking with hardcoded Keycloak URL. Rewrite to:

1. Accept `iam_api_url` as constructor parameter (no hardcoded URL)
2. Accept `keycloak_url`, `keycloak_username`, `keycloak_password`, `identity_provider` as constructor parameters
3. Use `lib.keycloak.link_saml_identity()` instead of inline `requests.post` calls
4. Accept `import_filename` parameter to support both IAM API and file-based import
5. Keep the column mapping, validation, and cleanup logic intact

```python
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

"""
User import class.

Reads user data from an IAM API endpoint or a local file, validates it,
and feeds it to a callback function (typically Ucs.set_user).
After each user is created, links the user to a SAML identity provider in Keycloak.
"""

import base64
import glob
import os
import random
import re
import sys
import logging
import pandas as pd
import requests

from lib.keycloak import link_saml_identity_with_credentials


class ImportUser:
    def __init__(
        self,
        callback,
        import_filename=None,
        iam_api_url=None,
        create_admin_accounts=False,
        use_images=False,
        password_recovery_email=None,
        keycloak_url=None,
        keycloak_username=None,
        keycloak_password=None,
        identity_provider="saml-umr",
    ):
        """
        Args:
            callback: Function to call for each user record (typically ucs.set_user)
            import_filename: Path to local file (ODS/XLSX) for file-based import
            iam_api_url: URL of IAM API endpoint for API-based import
            create_admin_accounts: If True, also create <username>-admin accounts
            use_images: If True, attach random profile pictures
            password_recovery_email: Override email for password recovery
            keycloak_url: Keycloak base URL for SAML linking
            keycloak_username: Keycloak admin username for SAML linking
            keycloak_password: Keycloak admin password for SAML linking
            identity_provider: SAML IdP alias in Keycloak (e.g., "saml-umr", "dfn-aai")
        """
        self.input_dir_imgs_base = os.path.join(
            os.path.dirname(os.path.abspath(__file__)), "..", "data", "images_"
        )
        self.callback = callback
        self.password_recovery_email = password_recovery_email
        self.keycloak_url = keycloak_url
        self.keycloak_username = keycloak_username
        self.keycloak_password = keycloak_password
        self.identity_provider = identity_provider

        self.columnnames_map = {
            "Username": "username",
            "Externe E-Mail": "email",
            "Vorname": "firstname",
            "Nachname": "lastname",
            "Anrede": "title",
            "Passwort": "password",
            "LDAP-Gruppen": "groups",
            "Organisationseinheit": "organisation",
            "Primäre Mailadresse": "mailPrimaryAddress",
            "OX Context": "oxContext",
        }

        # Load user data
        persons = self._load_users(import_filename, iam_api_url)
        if persons is None:
            return

        persons.rename(columns=self.columnnames_map, inplace=True)

        logging.info("Cleaning up list")

        # Cleanup list
        error_count = 0
        for index, person in persons.iterrows():
            if person["email"] == 0:
                persons.drop(index, inplace=True)
                continue
            if not isinstance(person["username"], str):
                logging.error(f"Missing username in '{person}'")
                error_count += 1
                continue
            if person["username"].strip() != person["username"]:
                logging.warning(f"Leading or trailing blank(s) found in username: '{person['username']}'")
                persons.at[index, "username"] = person["username"].strip()
            if person["email"].strip() != person["email"]:
                logging.warning(f"Leading or trailing blank(s) found in external email: '{person['email']}'")
                persons.at[index, "email"] = person["email"].strip()
            if "mailPrimaryAddress" in person and isinstance(person["mailPrimaryAddress"], str):
                if person["mailPrimaryAddress"].strip() != person["mailPrimaryAddress"]:
                    logging.warning(
                        f"Leading or trailing blank(s) found in internal email: '{person['mailPrimaryAddress']}'"
                    )
                    persons.at[index, "mailPrimaryAddress"] = person["mailPrimaryAddress"].strip()

        logging.info(f"Processing list with {len(persons.index)} lines.")
        logging.debug(f"Going to process the following list:\n{persons.to_string()}")

        # Validate list
        for index, person in persons.iterrows():
            if not bool(re.match(r"^[\w\d\.-]+$", person["username"], flags=re.IGNORECASE)):
                logging.error(f"Found invalid characters in username: '{person['username']}'")
                error_count += 1
            if not bool(re.match(r"^[\w\d\.\-_]+@[\w\d\.\-_]+$", person["email"], flags=re.IGNORECASE)):
                logging.error(f"Found invalid external email: '{person['email']}'")
                error_count += 1
            if "mailPrimaryAddress" in person and isinstance(person["mailPrimaryAddress"], str):
                if not bool(
                    re.match(r"^[\w\d\.\-_]+@[\w\d\.\-_]+$", person["mailPrimaryAddress"], flags=re.IGNORECASE)
                ):
                    logging.error(f"Found invalid primary email: '{person['mailPrimaryAddress']}'")
                    error_count += 1
            if "oxContext" in person and not pd.isna(persons.at[index, "oxContext"]):
                if not isinstance(person["oxContext"], (int, float)):
                    logging.error(
                        f"Invalid oxContext value for user '{person['username']}': {person['oxContext']}. Must be an integer."
                    )
                    error_count += 1

        if error_count > 0:
            sys.exit("! Found errors, please fix and rerun the script")

        # Process list
        for _, person in persons.iterrows():
            if self.password_recovery_email:
                person["email"] = self.password_recovery_email
            if "organisation" not in person or pd.isna(person["organisation"]):
                person["organisation"] = person["email"].rpartition("@")[-1]
            person["is_admin"] = False
            if use_images:
                person["jpegPhoto"] = self._get_image()

            callback(person)

            if create_admin_accounts:
                person["username"] = person["username"] + "-admin"
                person["is_admin"] = True
                callback(person)

            # Link SAML identity in Keycloak
            if self.keycloak_url and self.keycloak_username and self.keycloak_password:
                if link_saml_identity_with_credentials(
                    keycloak_url=self.keycloak_url,
                    username=person["username"].replace("-admin", "") if create_admin_accounts else person["username"],
                    admin_username=self.keycloak_username,
                    admin_password=self.keycloak_password,
                    identity_provider=self.identity_provider,
                ):
                    logging.info(f"  Linked SAML identity for {person['username']} -> {self.identity_provider}")
                else:
                    logging.warning(f"  Failed to link SAML identity for {person['username']}")
            else:
                logging.debug("  Skipping SAML linking (no Keycloak credentials configured)")

    def _load_users(self, import_filename, iam_api_url):
        """Load users from either an IAM API endpoint or a local file."""
        if iam_api_url:
            try:
                r = requests.get(iam_api_url, timeout=30)
                r.raise_for_status()
                provisioning_info = r.json()
                persons = pd.json_normalize(provisioning_info["accounts"])
                return persons
            except requests.RequestException as e:
                logging.error(f"Failed to fetch users from IAM API ({iam_api_url}): {e}")
                sys.exit(1)
        elif import_filename and os.path.isfile(import_filename):
            ext = os.path.splitext(import_filename)[1].lower()
            if ext in (".ods",):
                persons = pd.read_excel(import_filename, engine="odf")
            elif ext in (".xlsx",):
                persons = pd.read_excel(import_filename)
            elif ext in (".csv",):
                persons = pd.read_csv(import_filename)
            else:
                logging.error(f"Unsupported file format: {ext}")
                sys.exit(1)
            return persons
        else:
            if import_filename:
                logging.error(f"File to import from '{import_filename}' was not found.")
            else:
                logging.error("No IAM API URL or import filename provided.")
            sys.exit(1)

    def _get_image(self):
        """Get a random profile picture from the data directory."""
        if not hasattr(self, "_image_list"):
            self._image_list = []
        if len(self._image_list) == 0:
            for gender in ("m", "f"):
                img_dir = self.input_dir_imgs_base + gender
                if os.path.isdir(img_dir):
                    self._image_list.extend(glob.glob(os.path.join(img_dir, "*.jpg")))

        if not self._image_list:
            logging.warning("No profile images found in data directory")
            return None

        selected_image = random.choice(self._image_list)
        with open(selected_image, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode()
```

- [ ] **Step 2: Verify import**

Run: `cd opendesk-edu/scripts/user_import && python -c "from lib.import_user import ImportUser; print('OK')"`
Expected: OK

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/lib/import_user.py
git commit -m "feat(user-import): add user import class with configurable SAML linking"
```

### Task 5: Copy remaining lib files

**Files:**

- Create: `opendesk-edu/scripts/user_import/lib/argparse_types.py`
- Create: `opendesk-edu/scripts/user_import/lib/random_user.py`

- [ ] **Step 1: Copy `argparse_types.py` and `random_user.py`**

Copy from `user_import/lib/` with updated SPDX headers. Minimal changes — just headers.

For `random_user.py`, update the image path base to be relative to the module location (using `os.path.dirname(__file__)`) instead of hardcoded `"./data/images_"`.

- [ ] **Step 2: Verify imports**

Run: `cd opendesk-edu/scripts/user_import && python -c "from lib.argparse_types import opt2bool; from lib.random_user import RandomUser; print('OK')"`
Expected: OK

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/lib/argparse_types.py opendesk-edu/scripts/user_import/lib/random_user.py
git commit -m "feat(user-import): add argparse utility and random user generator"
```

---

## Chunk 2: Entry point scripts

### Task 6: Create `provision.py` (main entry point)

**Files:**

- Create: `opendesk-edu/scripts/user_import/provision.py`
- Reference: `user_import/user_import_udm_rest_api.py` (349 lines)

- [ ] **Step 1: Rewrite `provision.py`**

Based on `user_import_udm_rest_api.py` with these changes:

1. Import `NON_RECONCILE_GROUPS` from `lib.constants` (deduplicate)
2. Add `--iam_api_url` / `IAM_API_URL` argument (no hardcoded URL)
3. Add `--keycloak_url` / `KEYCLOAK_URL`, `--keycloak_api_username` / `KEYCLOAK_API_USERNAME`, `--keycloak_api_password` / `KEYCLOAK_API_PASSWORD` arguments
4. Add `--identity_provider` / `IDENTITY_PROVIDER` argument (default: `saml-umr`)
5. Pass Keycloak credentials to `ImportUser` constructor
6. Remove the inline SAML linking that was in the original `import_user.py` — it's now handled inside `ImportUser` via `lib.keycloak`
7. Keep all existing UDM/provisioning arguments intact

Key changes from original:

- `ImportUser` constructor now receives `keycloak_url`, `keycloak_username`, `keycloak_password`, `identity_provider`
- `NON_RECONCILE_GROUPS` imported from `lib.constants` instead of defined inline
- `iam_api_url` is a CLI argument, not hardcoded

- [ ] **Step 2: Verify the script parses args**

Run: `cd opendesk-edu/scripts/user_import && python provision.py --help`
Expected: Help output showing all arguments including `--iam_api_url`, `--keycloak_url`, `--identity_provider`

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/provision.py
git commit -m "feat(user-import): add provisioning entry point with SAML linking support"
```

### Task 7: Create cleaned `deprovision_disable.py`

**Files:**

- Create: `opendesk-edu/scripts/user_import/deprovision_disable.py`
- Reference: `user_import/deprovision_disable.py` (440 lines)

- [ ] **Step 1: Copy and clean `deprovision_disable.py`**

Changes from original:

1. Import `NON_RECONCILE_GROUPS` from `lib.constants` instead of defining inline (remove the duplicate at lines 37-48)
2. Add `--identity_provider` / `IDENTITY_PROVIDER` argument (pass to `remove_saml_identity_with_credentials`)
3. Keep `--iam_api_url` / `IAM_API_URL` as configurable (already present, good)
4. Keep `--keycloak_url` / `KEYCLOAK_URL` as configurable (already present, good)
5. Update imports to use `lib.keycloak` and `lib.constants`

- [ ] **Step 2: Verify**

Run: `cd opendesk-edu/scripts/user_import && python deprovision_disable.py --help`
Expected: Help output

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/deprovision_disable.py
git commit -m "feat(user-import): add phase 1 deprovision script (disable + unlink SAML)"
```

### Task 8: Create cleaned `deprovision_delete.py`

**Files:**

- Create: `opendesk-edu/scripts/user_import/deprovision_delete.py`
- Reference: `user_import/deprovision_delete.py` (385 lines)

- [ ] **Step 1: Copy and clean `deprovision_delete.py`**

Changes from original:

1. Update imports to use `lib.ucs` (already correct structure)
2. Add `--identity_provider` / `IDENTITY_PROVIDER` argument even though phase 2 doesn't use SAML (consistency)
3. Update SPDX headers
4. No functional changes needed — phase 2 is purely UCS-based (SAML was already removed in phase 1)

- [ ] **Step 2: Verify**

Run: `cd opendesk-edu/scripts/user_import && python deprovision_delete.py --help`
Expected: Help output

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/deprovision_delete.py
git commit -m "feat(user-import): add phase 2 deprovision script (permanent delete after grace period)"
```

---

## Chunk 3: Project configuration + tests + docs

### Task 9: Create `pyproject.toml` and `requirements.txt`

**Files:**

- Create: `opendesk-edu/scripts/user_import/pyproject.toml`
- Create: `opendesk-edu/scripts/user_import/requirements.txt`

- [ ] **Step 1: Create `pyproject.toml`**

```toml
[project]
name = "opendesk-edu-user-import"
version = "1.0.0"
description = "User provisioning, deprovisioning, and SAML identity linking for openDesk Edu"
requires-python = ">=3.12"
dependencies = [
    "requests>=2.31",
    "pandas>=2.0",
    "configargparse>=1.7",
    "python-dateutil>=2.8",
]

[project.optional-dependencies]
ods = ["odfpy>=1.4"]
xlsx = ["openpyxl>=3.1"]
dev = [
    "pytest>=8.0",
    "pytest-mock>=3.12",
    "ruff>=0.4",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]

[tool.ruff]
line-length = 120
target-version = "py312"
```

- [ ] **Step 2: Create `requirements.txt`**

```
requests>=2.31
pandas>=2.0
configargparse>=1.7
python-dateutil>=2.8
odfpy>=1.4
openpyxl>=3.1
```

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/pyproject.toml opendesk-edu/scripts/user_import/requirements.txt
git commit -m "feat(user-import): add project configuration and dependency declarations"
```

### Task 10: Create `Dockerfile`

**Files:**

- Create: `opendesk-edu/scripts/user_import/Dockerfile`
- Reference: `user_import/Dockerfile`

- [ ] **Step 1: Create Dockerfile**

Based on original but:

1. Copy only the necessary files (lib/, provision.py, deprovision_*.py, requirements.txt)
2. Do NOT copy data/, tests/, or any sensitive files
3. Add SPDX headers

- [ ] **Step 2: Commit**

```bash
git add opendesk-edu/scripts/user_import/Dockerfile
git commit -m "feat(user-import): add Dockerfile for containerized deployment"
```

### Task 11: Create test fixtures and UDM tests

**Files:**

- Create: `opendesk-edu/scripts/user_import/tests/__init__.py`
- Create: `opendesk-edu/scripts/user_import/tests/conftest.py`
- Create: `opendesk-edu/scripts/user_import/tests/test_ucs.py`

- [ ] **Step 1: Create test infrastructure**

Copy `tests/__init__.py` and `tests/conftest.py` from `user_import/tests/`, updating imports to use `lib.constants.NON_RECONCILE_GROUPS`.

For `test_ucs.py`: Copy from original but note that the original has many placeholder stubs (`assert True`). Keep those as-is for now — they can be filled in later. The key thing is that the import structure works.

- [ ] **Step 2: Run all tests**

Run: `cd opendesk-edu/scripts/user_import && python -m pytest tests/ -v`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add opendesk-edu/scripts/user_import/tests/
git commit -m "feat(user-import): add test infrastructure and fixtures"
```

### Task 12: Create README.md

**Files:**

- Create: `opendesk-edu/scripts/user_import/README.md`

- [ ] **Step 1: Write README**

Document:

1. Overview (what the tool does)
2. Prerequisites (Python 3.12+, UCS access, Keycloak admin, IAM API)
3. Configuration reference (all env vars / CLI args)
4. Provisioning workflow (provision.py)
5. Deprovisioning workflow (phase 1 disable + phase 2 delete)
6. SAML linking (how it works, configurable provider alias)
7. Docker deployment
8. Security notes (no hardcoded credentials, env vars only)
9. Development (how to run tests)

Follow the style of existing READMEs in opendesk-edu (e.g., `scripts/federation/README.md`).

- [ ] **Step 2: Commit**

```bash
git add opendesk-edu/scripts/user_import/README.md
git commit -m "docs(user-import): add usage and deployment documentation"
```

---

## Chunk 4: Roadmap updates

### Task 13: Update ROADMAP.md — add provisioning/deprovisioning + SATOSA

**Files:**

- Modify: `opendesk-edu/ROADMAP.md:37-51` (v1.1 DFN-AAI section)

- [ ] **Step 1: Add User Provisioning & Lifecycle section to v1.1**

After the existing "DFN-AAI / eduGAIN SAML Federation Support" section (after line 50), add a new subsection:

```markdown
### User Provisioning & Deprovisioning

Automate the full user lifecycle based on the university's IAM data. Users are provisioned
from an IAM API, linked to the external Shibboleth IdP in Keycloak, and deprovisioned in
two phases when they leave.

- [ ] Provision users from IAM API via UDM REST API (`scripts/user_import/provision.py`)
- [ ] Link provisioned users to external Shibboleth IdP in Keycloak (configurable provider alias)
- [ ] Phase 1 deprovisioning: disable accounts, unlink SAML identity, remove groups (`deprovision_disable.py`)
- [ ] Phase 2 deprovisioning: permanent deletion after configurable grace period (`deprovision_delete.py`)
- [ ] Containerized deployment via Docker/cronjob for scheduled sync
- [ ] Support for file-based import (CSV/ODS/XLSX) as alternative to IAM API
```

- [ ] **Step 2: Add SATOSA section to v1.1**

After the new User Provisioning section, add:

```markdown
### SATOSA Proxy for Federated Deployments

[SATOSA](https://github.com/IdentityPython/SATOSA) (Apache-2.0) is the standard SAML/OIDC
proxy for federated identity in research and education. For universities that need to connect
multiple external identity providers (e.g., DFN-AAI, eduGAIN, institutional Shibboleth IdPs),
SATOSA sits between the upstream IdPs and Keycloak, handling protocol translation,
attribute filtering, and consent management.

**Why SATOSA over Keycloak-native federation:**
- Protocol bridge: SAML 2.0 ↔ OIDC translation for legacy IdPs
- Attribute filtering: release different attributes per SP (per-entity filtering)
- Consent management: user consent UI for attribute release (required by some federations)
- Persistent identifier mapping: maps external `eduPersonPrincipalName` to internal Keycloak IDs
- Multi-federation support: connect to DFN-AAI, eduGAIN, and institutional IdPs simultaneously

- [ ] Helm chart for SATOSA deployment (PySATOSA + plugins)
- [ ] SAML 2.0 frontend: accept SAML assertions from upstream Shibboleth IdPs
- [ ] OIDC backend: translate to OIDC and proxy to Keycloak as upstream IdP
- [ ] Per-SP attribute filtering configuration (ConfigYAML-based)
- [ ] Persistent name identifier mapping (`eduPersonPrincipalName` → Keycloak username)
- [ ] Consent management plugin (attribute release consent UI)
- [ ] Integration with existing `scripts/federation/generate-metadata.sh` for SP metadata
- [ ] Health checks and monitoring endpoints
- [ ] Documentation: federation setup guide for deployers
```

- [ ] **Step 3: Update the "Not Planned" table**

Update the entry about Shibboleth IdP to reflect SATOSA:

Change:

```
| **Shibboleth IdP deployment** | Universities already run their own IdP. openDesk Edu integrates as a SAML SP, not an IdP provider. |
| **Keycloak as eduGAIN IdP** | SAML federation support is incomplete. Use Shibboleth IdP for federation, Keycloak for internal IAM. |
```

To:

```
| **Shibboleth IdP deployment** | Universities already run their own IdP. openDesk Edu integrates as a SAML SP via SATOSA proxy. |
| **Keycloak as eduGAIN IdP** | SAML federation support is incomplete. Use SATOSA + Shibboleth IdP for federation, Keycloak for internal IAM. |
```

- [ ] **Step 4: Update the Timeline**

Add SATOSA and user provisioning to the v1.1 timeline entry:

Change:

```
2026 Q2   v1.0  Core platform + 13 education services (ILIAS, Moodle, BBB, OpenCloud, SOGo, Etherpad, BookStack, Planka, Zammad, LimeSurvey, Draw.io, Excalidraw, SSP)
          v1.1  DFN-AAI federation + semester lifecycle + logout
```

To:

```
2026 Q2   v1.0  Core platform + 13 education services (ILIAS, Moodle, BBB, OpenCloud, SOGo, Etherpad, BookStack, Planka, Zammad, LimeSurvey, Draw.io, Excalidraw, SSP)
          v1.1  DFN-AAI federation + SATOSA proxy + user provisioning/deprovisioning + semester lifecycle + logout
```

- [ ] **Step 5: Commit**

```bash
git add opendesk-edu/ROADMAP.md
git commit -m "docs(roadmap): add user provisioning lifecycle and SATOSA proxy to v1.1"
```

---

## Chunk 5: F13 AI Assistant Integration

### Task 14: Create Helm chart for F13 AI Assistant

**Files:**

- Create: `opendesk-edu/helmfile/charts/f13/Chart.yaml`
- Create: `opendesk-edu/helmfile/charts/f13/values.yaml`
- Create: `opendesk-edu/helmfile/charts/f13/templates/` (deployment, service, configmap, secret, ingress, etc.)
- Reference: F13 source at `/home/weissto_local/git/f13/core/` (Docker Compose configs)

**F13 source (read-only):**

- `/home/weissto_local/git/f13/core/docker-compose.yml` — Full service topology (11 containers)
- `/home/weissto_local/git/f13/core/configs/general.yml` — Central config (auth, endpoints, CORS, DB)
- `/home/weissto_local/git/f13/core/configs/llm_models.yml` — LLM model definitions
- `/home/weissto_local/git/f13/core/configs/keycloak-test-realms/f13-realm.json` — Keycloak realm export
- `/home/weissto_local/git/f13/core/src/models/authentication.py` — JWT auth via PyJWKClient
- `/home/weissto_local/git/f13/frontend/Dockerfile` — Multi-stage node→nginx build
- `/home/weissto_local/git/f13/frontend/nginx/f13-frontend.conf.template` — Nginx reverse proxy

**F13 service topology:**

```
frontend (nginx:9999) → core (FastAPI:8000) → chat:8000, summary:8000, parser:8000, rag:8000, transcription:8000
                                                   → elasticsearch:9200, feedback-db (postgres), transcription-db (postgres)
                                                   → rabbitmq (for transcription)
```

**F13 container images** (from `registry.opencode.de/f13/microservices/`):
| Service | Image | GPU? |
|---------|-------|------|
| frontend | `frontend/main:latest` | No |
| core | `core/main:latest` | No |
| chat | `chat:v1.1.0` | No |
| summary | `summary/main:latest` | No |
| parser | `parser:v1.1.0` | Yes (EasyOCR) |
| rag | `rag:v1.1.0` | Yes (embeddings) |
| transcription | `transcription/transcription/main:latest` | No |
| transcription-inference | `transcription/inference/main:latest` | Yes (Whisper) |

**Keycloak integration points:**

- Frontend env vars: `KEYCLOAK_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID`, `KEYCLOAK_DISABLED`
- Core config (`general.yml`): `authentication.guest_mode`, `authentication.keycloak_base_url`, `authentication.keycloak_realm`, `authentication.audience`
- Auth flow: Frontend OIDC → JWT access token → Core validates via Keycloak JWKS
- Keycloak realm "f13" has client `f13-api` (public, standard flow), roles: `admin`, `user`
- Required JWT claims: `sub`, `sid`, `aud` (audience = `f13-api`)

**Secrets (5 files):**

- `llm_api.secret` — API key for LLM provider (Bearer/Basic auth)
- `feedback_db.secret` — PostgreSQL password for feedback DB
- `transcription_db.secret` — PostgreSQL password for transcription DB
- `rabbitmq.secret` — RabbitMQ password
- `huggingface_token.secret` — HuggingFace token for model downloads

- [ ] **Step 1: Create Chart.yaml**

```yaml
apiVersion: v2
name: f13
description: F13 AI Assistant — sovereign, model-agnostic AI for openDesk Edu
type: application
version: 0.1.0
appVersion: "1.1.0"
keywords:
  - ai
  - llm
  - chat
  - rag
  - summarization
  - transcription
home: https://f13-os.de/
sources:
  - https://gitlab.opencode.de/f13/dokumentation
maintainers:
  - name: openDesk Edu
```

- [ ] **Step 2: Create values.yaml with full configuration surface**

The values.yaml must expose:

- `global` block for shared config (image registry, Keycloak URL, ingress)
- `f13.enabled` toggle per microservice (chat, summary, parser, rag, transcription)
- `f13.authentication.guestMode` (default: false for production)
- `f13.authentication.keycloakBaseUrl`, `keycloakRealm`, `audience`
- `f13.llm` — model provider config (URL, auth secret reference, model names per service)
- `f13.elasticsearch` — use existing cluster or deploy new (host, port, memory)
- `f13.transcription` — optional, includes RabbitMQ, transcription-db, inference worker
- `f13.gpu` — node selectors, tolerations, resource limits for GPU services
- `f13.ingress` — hostname, TLS, path routing
- `f13.persistence` — PVC sizes for feedback-db, docling-models, transcription-data, transcription-models
- `f13.imagePullSecrets` — for `registry.opencode.de` if private

Key values structure:

```yaml
global:
  keycloakUrl: ""
  keycloakRealm: "opendesk"

f13:
  authentication:
    guestMode: false
    keycloakBaseUrl: ""  # auto-derived from global.keycloakUrl if empty
    keycloakRealm: ""    # auto-derived from global.keycloakRealm if empty
    audience: "f13-api"

  llm:
    provider: "openai-compatible"
    apiUrl: ""
    authSecretRef: "f13-llm-api-key"
    models:
      chat: ["llama-3.3-70b-instruct"]
      summary: ["mistral-small-3.1-24b-instruct"]
      rag: ["llama-3.3-70b-instruct"]
      embedding: ["jina-embeddings-v2-base-de"]

  chat:
    enabled: true
  summary:
    enabled: true
  parser:
    enabled: true
  rag:
    enabled: true
  transcription:
    enabled: false  # optional, heavy

  elasticsearch:
    existingHost: ""   # use existing ES cluster
    memory: "4Gi"

  ingress:
    enabled: true
    hostname: "f13.opendesk-edu.example"
    tlsSecretName: ""

  persistence:
    feedbackDb:
      size: "1Gi"
    doclingModels:
      size: "10Gi"
    transcriptionData:
      size: "5Gi"
    transcriptionModels:
      size: "10Gi"
```

- [ ] **Step 3: Create Kubernetes templates**

Required templates:

1. `_helpers.tpl` — common labels, image helpers, Keycloak URL derivation
2. `configmap-general.yaml` — `configs/general.yml` from values (service endpoints, auth, CORS, DB, logging)
3. `configmap-llm.yaml` — `configs/llm_models.yml` from values (model definitions)
4. `configmap-prompt-maps.yaml` — `configs/prompt_maps.yml` (system prompts, customizable)
5. `configmap-rag.yaml` — `configs/rag_pipeline_config.yml` (ES index, embedding, retrieval)
6. `configmap-transcription.yaml` — `configs/transcription_config.yml` + `transcription_models.yml`
7. `secret.yaml` — All 5 secrets (llm_api, feedback_db, transcription_db, rabbitmq, huggingface_token)
8. `deployment-core.yaml` — Core API (FastAPI, port 8000, health check /health)
9. `deployment-chat.yaml` — Chat microservice
10. `deployment-summary.yaml` — Summary microservice
11. `deployment-parser.yaml` — Parser microservice (GPU optional)
12. `deployment-rag.yaml` — RAG microservice (GPU optional)
13. `deployment-transcription.yaml` — Transcription microservice
14. `deployment-transcription-inference.yaml` — Transcription inference worker (GPU required)
15. `deployment-frontend.yaml` — Nginx serving Svelte SPA (port 9999)
16. `service-core.yaml` — ClusterIP for core API
17. `service-frontend.yaml` — ClusterIP for frontend
18. `ingress.yaml` — Ingress routing / to frontend
19. StatefulSet for elasticsearch (or use existing)
20. StatefulSets for postgres (feedback-db, transcription-db) or use existing
21. Deployment for rabbitmq (only if transcription enabled)
22. `networkpolicy.yaml` — Restrict inter-service traffic
23. `pdb.yaml` — Pod disruption budgets

- [ ] **Step 4: Create helmfile app config**

Create `opendesk-edu/helmfile/apps/f13/values.yaml.gotmpl` following existing patterns in `helmfile/apps/`.

- [ ] **Step 5: Create Keycloak bootstrap config**

Bootstrap the F13 OIDC client and roles in the existing opendesk Keycloak realm:

- Create client `f13-api` (public, standard flow, redirect URIs for F13 frontend)
- Create roles `f13-user` and `f13-admin`
- Configure UMA authorization resources (chat, summary, rag-file, rag-database, transcription, feedback)
- Create policies for resource access

- [ ] **Step 6: Validate with helm lint and template**

```bash
helm lint opendesk-edu/helmfile/charts/f13/
helm template f13 opendesk-edu/helmfile/charts/f13/ -f values.yaml
```

- [ ] **Step 7: Commit**

```bash
git add opendesk-edu/helmfile/charts/f13/ opendesk-edu/helmfile/apps/f13/
git commit -m "feat(f13): add Helm chart for F13 AI Assistant integration"
```

### Task 15: Update ROADMAP.md — replace generic LLM section with F13

**Files:**

- Modify: `opendesk-edu/ROADMAP.md:383-405` (v4.0 AI & Analytics section)

- [ ] **Step 1: Replace "Local LLM Integration" with F13**

Replace the generic v4.0 "Local LLM Integration" section with a concrete F13 integration section:

```markdown
### F13 AI Assistant

[F13](https://f13-os.de/) (MPL-2.0, InnoLab/Baden-Württemberg) is a sovereign, model-agnostic
AI assistant developed "by the administration for the administration." It provides chat, document
summarization, research (RAG), and transcription — all on-premise, no data leaves the cluster.

**Why F13 over building from scratch:**
- Production-ready with proven deployment in German public administration
- Keycloak-native authentication (OIDC/JWT, UMA authorization, RBAC)
- Model-agnostic: works with local LLMs (vLLM, Ollama) or cloud providers
- Modular microservice architecture — enable/disable features per deployment
- Active open-source community (openCoDE, GitLab)
- DSGVO-compliant: no data leaves the cluster, no model training on user data

**F13 Microservices:**

| Service | What | GPU? |
|:--------|:-----|:----:|
| **Chat** | LLM-powered chat for text work | No |
| **Summary** | Document summarization (PDF, DOCX, TXT) | No |
| **RAG** | Retrieval-augmented research on uploaded documents | Yes |
| **Parser** | Document parsing (Docling/EasyOCR) | Yes |
| **Transcription** | Audio/video transcription with speaker detection | Yes |

**Integration Architecture:**
```

openDesk Portal → F13 Frontend (Svelte/nginx)
                    → F13 Core (FastAPI) — validates JWT via Keycloak JWKS
                    → Chat / Summary / RAG / Transcription microservices
                    → LLM Inference (vLLM/Ollama or cloud API)

```

- [ ] Helm chart for F13 (all microservices + dependencies)
- [ ] Keycloak OIDC client bootstrap (`f13-api` client, roles, UMA policies)
- [ ] Shared Keycloak realm: F13 uses the same Keycloak as openDesk (single sign-on)
- [ ] LLM provider integration: vLLM for local inference, or cloud API fallback
- [ ] Portal tile for F13 frontend
- [ ] GPU scheduling for RAG, Parser, and Transcription Inference
- [ ] Elasticsearch for RAG vector storage (use existing or deploy new)
- [ ] Monitoring integration (Prometheus metrics)
- [ ] Backup integration with k8up (PostgreSQL, Elasticsearch)
- [ ] Documentation: F13 deployment guide for openDesk Edu operators
```

- [ ] **Step 2: Update the v4.0 header**

Change:

```
## v4.0 — AI & Analytics
```

To:

```
## v4.0 — AI & Analytics (F13)
```

- [ ] **Step 3: Update the Timeline**

Change:

```
2028 Q2   v4.0  Local LLM + xAPI analytics
```

To:

```
2028 Q1   v4.0  F13 AI Assistant (chat, summary, RAG, transcription)
2028 Q2   v4.1  xAPI learning analytics
```

- [ ] **Step 4: Commit**

```bash
git add opendesk-edu/ROADMAP.md
git commit -m "docs(roadmap): add F13 AI Assistant integration to v4.0"
```

---

## Summary

| Chunk | Tasks | What |
|:------|:------|:-----|
| 1 | 1-5 | lib module: constants, keycloak (link+remove), ucs, import_user, random_user, argparse_types |
| 2 | 6-8 | Entry points: provision.py, deprovision_disable.py, deprovision_delete.py |
| 3 | 9-12 | Project config: pyproject.toml, Dockerfile, tests, README |
| 4 | 13 | ROADMAP.md: user provisioning lifecycle + SATOSA for federated instances |
| 5 | 14-15 | F13 AI Assistant: Helm chart + Keycloak bootstrap + roadmap update |

**Key cleaning decisions:**

- `NON_RECONCILE_GROUPS` → `lib/constants.py` (single source of truth)
- Hardcoded IAM API URL → `--iam_api_url` CLI/env var
- Hardcoded Keycloak URL/creds → `--keycloak_url`, `--keycloak_api_username`, `--keycloak_api_password`
- Hardcoded `saml-umr` → `--identity_provider` (configurable)
- `link_users.py` logic → merged into `lib/keycloak.py:link_saml_identity()`
- Inline SAML linking in `import_user.py` → replaced with `lib.keycloak.link_saml_identity_with_credentials()`
- Sensitive data (passwords, user records, logs) → NOT moved
