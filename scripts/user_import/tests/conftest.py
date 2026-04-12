# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

import pytest
from unittest.mock import MagicMock

from lib.constants import NON_RECONCILE_GROUPS


@pytest.fixture
def mock_ucs():
    ucs = MagicMock()
    ucs.user_base = "cn=users,dc=swp-ldap,dc=internal"
    ucs.group_base = "cn=groups,dc=swp-ldap,dc=internal"
    ucs.maildomain_base = "cn=domain,cn=mail,dc=swp-ldap,dc=internal"
    ucs.adm_username = "Administrator"
    ucs.adm_password = "test_password"
    ucs.base_url = "test.domain"
    ucs.maildomain = "test.domain"
    ucs.request_url = "https://portal.test.domain"
    ucs.path_prefix = "/univention"
    ucs.verify_certificate = True
    return ucs


@pytest.fixture
def test_user_data():
    return {
        "username": "testuser",
        "firstname": "Test",
        "lastname": "User",
        "email": "test@example.com",
        "password": "TestPassword123!",
        "disabled": False,
        "groups": ["cn=Domain Users,cn=groups,dc=swp-ldap,dc=internal"],
        "description": "Test user for unit tests",
    }


@pytest.fixture
def mock_keycloak_response():
    return {
        "access_token": "mock_token_12345",
        "expires_in": 300,
        "refresh_token": "mock_refresh_token",
        "token_type": "Bearer",
    }


@pytest.fixture
def mock_keycloak_user_response():
    return [
        {
            "id": "user-uuid-12345",
            "username": "testuser",
            "email": "test@example.com",
            "enabled": True,
        }
    ]


@pytest.fixture
def non_reconcile_groups():
    return NON_RECONCILE_GROUPS
