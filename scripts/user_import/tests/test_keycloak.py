# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: AGPL-3.0-or-later

from unittest.mock import patch, MagicMock

import pytest
import requests

from lib.keycloak import (
    get_keycloak_token,
    get_keycloak_user_id,
    link_saml_identity,
    remove_saml_identity,
    remove_saml_identity_with_credentials,
    link_saml_identity_with_credentials,
)

BASE_URL = "https://id.example.com"
TOKEN = "mock-access-token"
USER_ID = "user-uuid-12345"
USERNAME = "testuser"
ADMIN_USER = "admin"
ADMIN_PASS = "admin-secret"


@pytest.fixture
def mock_token_response():
    resp = MagicMock()
    resp.status_code = 200
    resp.json.return_value = {"access_token": TOKEN, "expires_in": 300}
    resp.raise_for_status.return_value = None
    return resp


@pytest.fixture
def mock_user_lookup_response():
    resp = MagicMock()
    resp.status_code = 200
    resp.json.return_value = [{"id": USER_ID, "username": USERNAME, "enabled": True}]
    resp.raise_for_status.return_value = None
    return resp


@pytest.fixture
def mock_success_response():
    resp = MagicMock()
    resp.status_code = 204
    resp.text = ""
    resp.raise_for_status.return_value = None
    return resp


class TestGetKeycloakToken:
    @patch("lib.keycloak.requests.post")
    def test_returns_token_on_success(self, mock_post, mock_token_response):
        mock_post.return_value = mock_token_response
        result = get_keycloak_token(BASE_URL, ADMIN_USER, ADMIN_PASS)
        assert result == TOKEN

    @patch("lib.keycloak.requests.post")
    def test_returns_none_on_401(self, mock_post):
        resp = MagicMock()
        resp.status_code = 401
        resp.raise_for_status.side_effect = requests.HTTPError("Unauthorized")
        mock_post.return_value = resp
        result = get_keycloak_token(BASE_URL, ADMIN_USER, "wrong-pass")
        assert result is None

    @patch("lib.keycloak.requests.post")
    def test_returns_none_on_connection_error(self, mock_post):
        mock_post.side_effect = requests.ConnectionError("Connection refused")
        result = get_keycloak_token(BASE_URL, ADMIN_USER, ADMIN_PASS)
        assert result is None

    @patch("lib.keycloak.requests.post")
    def test_uses_custom_realm(self, mock_post, mock_token_response):
        mock_post.return_value = mock_token_response
        get_keycloak_token(BASE_URL, ADMIN_USER, ADMIN_PASS, realm="custom-realm")
        call_args = mock_post.call_args
        assert "custom-realm" in call_args[0][0]


class TestGetKeycloakUserId:
    @patch("lib.keycloak.requests.get")
    def test_returns_user_id_on_success(self, mock_get, mock_user_lookup_response):
        mock_get.return_value = mock_user_lookup_response
        result = get_keycloak_user_id(BASE_URL, USERNAME, TOKEN)
        assert result == USER_ID

    @patch("lib.keycloak.requests.get")
    def test_returns_none_when_user_not_found(self, mock_get):
        resp = MagicMock()
        resp.status_code = 200
        resp.json.return_value = []
        resp.raise_for_status.return_value = None
        mock_get.return_value = resp
        result = get_keycloak_user_id(BASE_URL, "nonexistent", TOKEN)
        assert result is None

    @patch("lib.keycloak.requests.get")
    def test_returns_none_on_connection_error(self, mock_get):
        mock_get.side_effect = requests.ConnectionError("Connection refused")
        result = get_keycloak_user_id(BASE_URL, USERNAME, TOKEN)
        assert result is None

    @patch("lib.keycloak.requests.get")
    def test_uses_custom_realm(self, mock_get, mock_user_lookup_response):
        mock_get.return_value = mock_user_lookup_response
        get_keycloak_user_id(BASE_URL, USERNAME, TOKEN, realm="custom-realm")
        call_args = mock_get.call_args
        assert "custom-realm" in call_args[0][0]


class TestLinkSamlIdentity:
    @patch("lib.keycloak.requests.post")
    @patch("lib.keycloak.requests.get")
    def test_returns_true_on_success(
        self, mock_get, mock_post, mock_user_lookup_response, mock_success_response
    ):
        mock_get.return_value = mock_user_lookup_response
        mock_post.return_value = mock_success_response
        result = link_saml_identity(BASE_URL, USERNAME, TOKEN)
        assert result is True

    @patch("lib.keycloak.requests.post")
    @patch("lib.keycloak.requests.get")
    def test_returns_true_on_409_conflict(
        self, mock_get, mock_post, mock_user_lookup_response
    ):
        mock_get.return_value = mock_user_lookup_response
        link_resp = MagicMock()
        link_resp.status_code = 409
        mock_post.return_value = link_resp
        result = link_saml_identity(BASE_URL, USERNAME, TOKEN)
        assert result is True

    @patch("lib.keycloak.requests.post")
    @patch("lib.keycloak.requests.get")
    def test_returns_false_when_user_not_found(self, mock_get, mock_post):
        resp = MagicMock()
        resp.status_code = 200
        resp.json.return_value = []
        resp.raise_for_status.return_value = None
        mock_get.return_value = resp
        result = link_saml_identity(BASE_URL, "nonexistent", TOKEN)
        assert result is False

    @patch("lib.keycloak.requests.get")
    def test_returns_false_on_connection_error(self, mock_get):
        mock_get.side_effect = requests.ConnectionError("Connection refused")
        result = link_saml_identity(BASE_URL, USERNAME, TOKEN)
        assert result is False

    @patch("lib.keycloak.requests.post")
    @patch("lib.keycloak.requests.get")
    def test_uses_custom_identity_provider(
        self, mock_get, mock_post, mock_user_lookup_response, mock_success_response
    ):
        mock_get.return_value = mock_user_lookup_response
        mock_post.return_value = mock_success_response
        link_saml_identity(BASE_URL, USERNAME, TOKEN, identity_provider="saml-custom")
        call_args = mock_post.call_args
        assert "saml-custom" in call_args[0][0]


class TestRemoveSamlIdentity:
    @patch("lib.keycloak.requests.delete")
    @patch("lib.keycloak.requests.get")
    def test_returns_true_on_204(
        self, mock_get, mock_delete, mock_user_lookup_response, mock_success_response
    ):
        mock_get.return_value = mock_user_lookup_response
        mock_delete.return_value = mock_success_response
        result = remove_saml_identity(BASE_URL, USERNAME, TOKEN)
        assert result is True

    @patch("lib.keycloak.requests.delete")
    @patch("lib.keycloak.requests.get")
    def test_returns_true_on_404_already_removed(
        self, mock_get, mock_delete, mock_user_lookup_response
    ):
        mock_get.return_value = mock_user_lookup_response
        resp_404 = MagicMock()
        resp_404.status_code = 404
        mock_delete.return_value = resp_404
        result = remove_saml_identity(BASE_URL, USERNAME, TOKEN)
        assert result is True

    @patch("lib.keycloak.requests.get")
    def test_returns_false_when_user_not_found(self, mock_get):
        resp = MagicMock()
        resp.status_code = 200
        resp.json.return_value = []
        resp.raise_for_status.return_value = None
        mock_get.return_value = resp
        result = remove_saml_identity(BASE_URL, "nonexistent", TOKEN)
        assert result is False

    @patch("lib.keycloak.requests.get")
    def test_returns_false_on_connection_error(self, mock_get):
        mock_get.side_effect = requests.ConnectionError("Connection refused")
        result = remove_saml_identity(BASE_URL, USERNAME, TOKEN)
        assert result is False


class TestRemoveSamlIdentityWithCredentials:
    @patch("lib.keycloak.remove_saml_identity")
    @patch("lib.keycloak.get_keycloak_token")
    def test_returns_true_on_success(self, mock_get_token, mock_remove):
        mock_get_token.return_value = TOKEN
        mock_remove.return_value = True
        result = remove_saml_identity_with_credentials(
            BASE_URL, USERNAME, ADMIN_USER, ADMIN_PASS
        )
        assert result is True
        mock_get_token.assert_called_once_with(BASE_URL, ADMIN_USER, ADMIN_PASS)

    @patch("lib.keycloak.remove_saml_identity")
    @patch("lib.keycloak.get_keycloak_token")
    def test_returns_false_on_auth_failure(self, mock_get_token, mock_remove):
        mock_get_token.return_value = None
        result = remove_saml_identity_with_credentials(
            BASE_URL, USERNAME, ADMIN_USER, ADMIN_PASS
        )
        assert result is False
        mock_remove.assert_not_called()

    @patch("lib.keycloak.remove_saml_identity")
    @patch("lib.keycloak.get_keycloak_token")
    def test_passes_identity_provider(self, mock_get_token, mock_remove):
        mock_get_token.return_value = TOKEN
        mock_remove.return_value = True
        remove_saml_identity_with_credentials(
            BASE_URL, USERNAME, ADMIN_USER, ADMIN_PASS, identity_provider="saml-custom"
        )
        mock_remove.assert_called_once_with(
            BASE_URL, USERNAME, TOKEN, "opendesk", "saml-custom"
        )


class TestLinkSamlIdentityWithCredentials:
    @patch("lib.keycloak.link_saml_identity")
    @patch("lib.keycloak.get_keycloak_token")
    def test_returns_true_on_success(self, mock_get_token, mock_link):
        mock_get_token.return_value = TOKEN
        mock_link.return_value = True
        result = link_saml_identity_with_credentials(
            BASE_URL, USERNAME, ADMIN_USER, ADMIN_PASS
        )
        assert result is True

    @patch("lib.keycloak.link_saml_identity")
    @patch("lib.keycloak.get_keycloak_token")
    def test_returns_false_on_auth_failure(self, mock_get_token, mock_link):
        mock_get_token.return_value = None
        result = link_saml_identity_with_credentials(
            BASE_URL, USERNAME, ADMIN_USER, ADMIN_PASS
        )
        assert result is False
        mock_link.assert_not_called()

    @patch("lib.keycloak.link_saml_identity")
    @patch("lib.keycloak.get_keycloak_token")
    def test_passes_identity_provider(self, mock_get_token, mock_link):
        mock_get_token.return_value = TOKEN
        mock_link.return_value = True
        link_saml_identity_with_credentials(
            BASE_URL, USERNAME, ADMIN_USER, ADMIN_PASS, identity_provider="saml-custom"
        )
        mock_link.assert_called_once_with(
            BASE_URL, USERNAME, TOKEN, "opendesk", "saml-custom"
        )
