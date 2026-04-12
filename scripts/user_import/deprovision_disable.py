#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

"""
Phase 1 Deprovisioning Script: Disable Users Missing from IAM API
"""

import logging
import configargparse
import requests

from lib.constants import NON_RECONCILE_GROUPS, DEFAULT_IDENTITY_PROVIDER
from lib.ucs import Ucs
from lib.keycloak import remove_saml_identity_with_credentials
from lib.common import parse_bool_string, setup_logging, create_ucs_options, get_timestamp, get_default_output_filename


def parse_args() -> configargparse.ArgumentParser:
    p = configargparse.ArgParser()

    p.add(
        "--udm_api_username",
        env_var="UDM_API_USERNAME",
        default="Administrator",
        help="User to authenticate against the UDM REST API with.",
    )
    p.add(
        "--udm_api_password",
        env_var="UDM_API_PASSWORD",
        required=True,
        help="Password for the UDM REST API user.",
    )
    p.add(
        "--keycloak_api_username",
        env_var="KEYCLOAK_API_USERNAME",
        default="admin",
        help="Keycloak admin username for SAML identity removal.",
    )
    p.add(
        "--keycloak_api_password",
        env_var="KEYCLOAK_API_PASSWORD",
        required=True,
        help="Keycloak admin password for SAML identity removal.",
    )
    p.add(
        "--keycloak_url",
        env_var="KEYCLOAK_URL",
        default=None,
        help="Keycloak URL (default: derived from import_domain)",
    )
    p.add(
        "--identity_provider",
        env_var="IDENTITY_PROVIDER",
        default=DEFAULT_IDENTITY_PROVIDER,
        help=f"Keycloak identity provider alias for SAML operations. Default: {DEFAULT_IDENTITY_PROVIDER}",
    )
    p.add(
        "--import_domain",
        env_var="IMPORT_DOMAIN",
        required=True,
        help="The domain name of your openDesk instance.",
    )
    p.add(
        "--import_maildomain",
        env_var="IMPORT_MAILDOMAIN",
        required=False,
        help="Optional: If using a different maildomain.",
    )
    p.add(
        "--iam_api_url",
        env_var="IAM_API_URL",
        default="https://iam-api-dev.hrz.uni-marburg.de/openDesk/v1.0/openDesk_account_depro",
        help="IAM API endpoint to fetch active users.",
    )
    p.add(
        "--loglevel",
        env_var="LOGLEVEL",
        default="INFO",
        help="Set the loglevel: DEBUG, INFO, WARNING, ERROR, CRITICAL.",
    )
    p.add("--logpath", env_var="LOGPATH", default="./logs", help="Path for log files.")
    p.add(
        "--output_deprovisioned_filename",
        env_var="OUTPUT_DEPROVISIONED_FILENAME",
        required=False,
        help="Output file for deprovisioned users. Default: deprovisioned-{domain}-{timestamp}.txt",
    )
    p.add(
        "--dry_run",
        env_var="DRY_RUN",
        default=False,
        type=parse_bool_string,
        help="If True, only log what would be done without making changes.",
    )
    p.add(
        "--verify_certificate",
        env_var="VERIFY_CERTIFICATE",
        default=True,
        type=parse_bool_string,
        help="Verify SSL certificates.",
    )
    p.add(
        "--enforce_ipv4",
        env_var="ENFORCE_IPV4",
        default=False,
        type=parse_bool_string,
        help="Enforce IPv4 communication.",
    )
    p.add(
        "--localhost_port",
        env_var="LOCALHOST_PORT",
        default=None,
        type=int,
        help="Port for localhost connections (tunnel to remote UDM REST API).",
    )

    return p.parse_args()


def get_iam_api_users(iam_api_url: str) -> set[str]:
    try:
        response = requests.get(iam_api_url, timeout=30)
        response.raise_for_status()
        data = response.json()

        usernames = set()
        if "accounts" in data:
            for account in data["accounts"]:
                if "username" in account:
                    usernames.add(account["username"].lower())

        logging.info(f"Found {len(usernames)} active users in IAM API")
        return usernames

    except requests.RequestException as e:
        logging.error(f"Failed to fetch IAM API users: {e}")
        return set()


def get_ucs_users(ucs: Ucs) -> set[str]:
    try:
        users = ucs._Ucs__get_object_list("user", "user")
        usernames = set()

        for user in users:
            dn = user.get("dn", "")
            if dn.startswith("uid="):
                username = dn.split(",")[0].replace("uid=", "")
                usernames.add(username.lower())

        logging.info(f"Found {len(usernames)} users in UCS")
        return usernames
    except Exception as e:
        logging.error(f"Failed to get UCS users: {e}")
        return set()


def deprovision_user(
    ucs: Ucs,
    username: str,
    keycloak_url: str,
    keycloak_username: str,
    keycloak_password: str,
    identity_provider: str,
    timestamp: str,
    dry_run: bool = False,
) -> bool:
    logging.info(f"Deprovisioning user: {username}")

    if dry_run:
        logging.info(f"  [DRY RUN] Would disable user {username}")
        logging.info(f"  [DRY RUN] Would remove SAML identity for {username}")
        logging.info(f"  [DRY RUN] Would remove groups for {username}")
        return True

    success = True

    if not ucs.disable_user(username, timestamp):
        logging.error(f"  Failed to disable user {username}")
        success = False
    else:
        logging.info(f"  Disabled user {username}")

    try:
        if remove_saml_identity_with_credentials(
            keycloak_url=keycloak_url,
            username=username,
            admin_username=keycloak_username,
            admin_password=keycloak_password,
            identity_provider=identity_provider,
        ):
            logging.info(f"  Removed SAML identity for {username}")
        else:
            logging.warning(f"  Could not remove SAML identity for {username} (may not exist)")
    except Exception as e:
        logging.error(f"  Error removing SAML identity for {username}: {e}")

    if not ucs.remove_groups_except(username, NON_RECONCILE_GROUPS):
        logging.error(f"  Failed to remove groups for {username}")
        success = False
    else:
        logging.info(f"  Removed groups for {username}")

    return success


def main() -> None:
    options = parse_args()
    setup_logging(options, "deprovision_disable.py")

    timestamp = get_timestamp()

    if options.output_deprovisioned_filename:
        output_file = options.output_deprovisioned_filename
    else:
        output_file = get_default_output_filename("deprovisioned", options.import_domain)

    keycloak_url = options.keycloak_url
    if not keycloak_url:
        keycloak_url = f"https://id.{options.import_domain}"

    maildomain = options.import_maildomain or options.import_domain

    ucs_options = create_ucs_options(
        enforce_ipv4=options.enforce_ipv4,
        localhost_port=options.localhost_port,
        verify_certificate=options.verify_certificate,
    )

    ucs = Ucs(
        adm_username=options.udm_api_username,
        adm_password=options.udm_api_password,
        base_url=options.import_domain,
        maildomain=maildomain,
        options_object=ucs_options,
    )

    iam_users = get_iam_api_users(options.iam_api_url)
    ucs_users = get_ucs_users(ucs)

    users_to_deprovision = ucs_users - iam_users

    logging.info(f"Found {len(users_to_deprovision)} users to deprovision")

    if not users_to_deprovision:
        logging.info("No users need deprovisioning.")
        return

    deprovisioned_count = 0
    failed_count = 0

    for username in sorted(users_to_deprovision):
        if username.endswith("-admin"):
            continue

        if deprovision_user(
            ucs=ucs,
            username=username,
            keycloak_url=keycloak_url,
            keycloak_username=options.keycloak_api_username,
            keycloak_password=options.keycloak_api_password,
            identity_provider=options.identity_provider,
            timestamp=timestamp,
            dry_run=options.dry_run,
        ):
            deprovisioned_count += 1

            with open(output_file, "a") as f:
                f.write(f"{username}\t{timestamp}\n")

            admin_username = f"{username}-admin"
            if admin_username in ucs_users:
                logging.info(f"Deprovisioning admin account: {admin_username}")
                deprovision_user(
                    ucs=ucs,
                    username=admin_username,
                    keycloak_url=keycloak_url,
                    keycloak_username=options.keycloak_api_username,
                    keycloak_password=options.keycloak_api_password,
                    identity_provider=options.identity_provider,
                    timestamp=timestamp,
                    dry_run=options.dry_run,
                )
                with open(output_file, "a") as f:
                    f.write(f"{admin_username}\t{timestamp}\n")
        else:
            failed_count += 1

    logging.info("=" * 50)
    logging.info("Deprovision Summary:")
    logging.info(f"  Users deprovisioned: {deprovisioned_count}")
    logging.info(f"  Failed: {failed_count}")
    logging.info(f"  Output file: {output_file}")
    ucs.summary()


if __name__ == "__main__":
    main()
