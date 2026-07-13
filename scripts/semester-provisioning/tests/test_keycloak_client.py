"""Tests for Keycloak Admin API client."""

import pytest
from sync.keycloak_client import KeycloakClient, KeycloakConfig, KeycloakClientError


@pytest.fixture
def config():
    return KeycloakConfig(
        base_url="https://keycloak.test",
        realm="testrealm",
        client_id="test-client",
        client_secret="test-secret",
        verify_ssl=False,
    )


@pytest.fixture
def client(config):
    return KeycloakClient(config)


class TestKeycloakClient:
    def test_get_user_by_username_found(self, client, httpx_mock):
        httpx_mock.add_response(
            url="https://keycloak.test/realms/testrealm/protocol/openid-connect/token",
            json={"access_token": "test-token", "expires_in": 60},
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users?username=jdoe&exact=true",
            json=[{"id": "user-123", "username": "jdoe", "email": "j@test.de"}],
        )
        user = client.get_user_by_username("jdoe")
        assert user is not None
        assert user["id"] == "user-123"

    def test_get_user_by_username_not_found(self, client, httpx_mock):
        httpx_mock.add_response(
            url="https://keycloak.test/realms/testrealm/protocol/openid-connect/token",
            json={"access_token": "test-token", "expires_in": 60},
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users?username=nonexistent&exact=true",
            json=[],
        )
        user = client.get_user_by_username("nonexistent")
        assert user is None

    def test_create_user(self, client, httpx_mock):
        httpx_mock.add_response(
            url="https://keycloak.test/realms/testrealm/protocol/openid-connect/token",
            json={"access_token": "test-token", "expires_in": 60},
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users",
            status_code=201,
            headers={"Location": "https://keycloak.test/admin/realms/testrealm/users/new-id-456"},
        )
        user_id = client.create_user({"username": "newuser", "email": "n@test.de"})
        assert user_id == "new-id-456"

    def test_disable_user(self, client, httpx_mock):
        httpx_mock.add_response(
            url="https://keycloak.test/realms/testrealm/protocol/openid-connect/token",
            json={"access_token": "test-token", "expires_in": 60},
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users/user-123",
            method="PUT",
            status_code=204,
        )
        client.disable_user("user-123")

    def test_sync_user_groups(self, client, httpx_mock):
        httpx_mock.add_response(
            url="https://keycloak.test/realms/testrealm/protocol/openid-connect/token",
            json={"access_token": "test-token", "expires_in": 60},
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/groups",
            json=[
                {"id": "g1", "name": "group-a"},
                {"id": "g2", "name": "group-b"},
                {"id": "g3", "name": "group-c"},
            ],
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users/user-123/groups",
            json=[{"id": "g1", "name": "group-a"}, {"id": "g2", "name": "group-b"}],
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users/user-123/groups/g2",
            method="DELETE",
            status_code=204,
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users/user-123/groups/g3",
            method="PUT",
            status_code=204,
        )
        result = client.sync_user_groups("user-123", {"group-a", "group-c"})
        assert "group-b" in result["removed"]
        assert "group-c" in result["added"]

    def test_api_error_raises(self, client, httpx_mock):
        httpx_mock.add_response(
            url="https://keycloak.test/realms/testrealm/protocol/openid-connect/token",
            json={"access_token": "test-token", "expires_in": 60},
        )
        httpx_mock.add_response(
            url="https://keycloak.test/admin/realms/testrealm/users/bad-id",
            status_code=404,
        )
        with pytest.raises(KeycloakClientError):
            client.get_user("bad-id")
