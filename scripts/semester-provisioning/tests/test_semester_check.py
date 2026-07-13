"""Tests for semester re-registration check."""

import pytest
from unittest import mock
from sync.semester_check import process_semester_check


@pytest.mark.asyncio
async def test_semester_check_mocked(monkeypatch):
    """Test with mocked LDAP and Keycloak."""

    monkeypatch.setenv("HISINONE_RE_REGISTRATION_GRACE", "30")
    monkeypatch.setenv("HISINONE_CURRENT_SEMESTER", "2026ws")
    monkeypatch.setenv("HISINONE_LDAP_BIND_PASSWORD", "test-pw")
    monkeypatch.setenv("KEYCLOAK_URL", "https://keycloak.test")
    monkeypatch.setenv("KEYCLOAK_REALM", "testrealm")
    monkeypatch.setenv("KEYCLOAK_CLIENT_ID", "test-client")
    monkeypatch.setenv("KEYCLOAK_CLIENT_SECRET", "test-secret")

    # Mock LDAP query to return enrolled users
    mock_ldap = mock.MagicMock(return_value={"student1", "student2", "student3"})

    with mock.patch("sync.semester_check.get_enrolled_usernames_from_ldap", mock_ldap):
        # Mock KeycloakClient
        with mock.patch("sync.semester_check.KeycloakClient") as MockKC:
            kc_instance = mock.MagicMock()
            MockKC.return_value = kc_instance

            # Simulate the _request method that returns users
            kc_instance._request.return_value.json.return_value = [
                {"id": "u1", "username": "student1", "enabled": True, "attributes": {"semester": ["2026ws"]}},
                {"id": "u2", "username": "student2", "enabled": False, "attributes": {"semester": ["2026ws"]}},
                {"id": "u3", "username": "student3", "enabled": True, "attributes": {"semester": ["2026ws"]}},
                {"id": "u4", "username": "droppedout", "enabled": True, "attributes": {"semester": ["2026ws"]}},
            ]

            result = process_semester_check(dry_run=True)
            assert result["disabled"] == 0  # dry_run
