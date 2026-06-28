# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: AGPL-3.0-or-later

import requests
import logging
from typing import Optional

from lib.constants import (
    DEFAULT_REALM,
    DEFAULT_KEYCLOAK_MASTER_REALM,
    DEFAULT_IDENTITY_PROVIDER,
)


def get_keycloak_token(
    keycloak_url: str,
    username: str,
    password: str,
    realm: str = DEFAULT_KEYCLOAK_MASTER_REALM,
) -> Optional[str]:
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
) -> bool:
    user_id = get_keycloak_user_id(keycloak_url, username, access_token, realm)
    if not user_id:
        logging.warning(
            f"User {username} not found in Keycloak, cannot link SAML identity"
        )
        return False

    link_url = f"{keycloak_url}/admin/realms/{realm}/users/{user_id}/federated-identity/{identity_provider}"
    headers = {"Authorization": f"Bearer {access_token}"}

    try:
        response = requests.post(
            link_url,
            headers=headers,
            json={"userId": username, "userName": username},
        )
        if response.status_code in (204, 200):
            logging.info(f"SAML identity linked for user {username}")
            return True
        elif response.status_code == 409:
            logging.info(f"SAML identity already linked for user {username}")
            return True
        else:
            logging.warning(
                f"Unexpected status {response.status_code} linking SAML for {username}"
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
    user_id = get_keycloak_user_id(keycloak_url, username, access_token, realm)
    if not user_id:
        logging.warning(
            f"User {username} not found in Keycloak, cannot remove SAML identity"
        )
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
            logging.warning(
                f"Unexpected status {response.status_code} removing SAML for {username}"
            )
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
    access_token = get_keycloak_token(keycloak_url, admin_username, admin_password)
    if not access_token:
        logging.error("Failed to authenticate with Keycloak")
        return False

    return remove_saml_identity(
        keycloak_url, username, access_token, realm, identity_provider
    )


def link_saml_identity_with_credentials(
    keycloak_url: str,
    username: str,
    admin_username: str,
    admin_password: str,
    realm: str = DEFAULT_REALM,
    identity_provider: str = DEFAULT_IDENTITY_PROVIDER,
) -> bool:
    access_token = get_keycloak_token(keycloak_url, admin_username, admin_password)
    if not access_token:
        logging.error("Failed to authenticate with Keycloak")
        return False

    return link_saml_identity(
        keycloak_url, username, access_token, realm, identity_provider
    )
