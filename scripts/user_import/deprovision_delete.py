#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

"""
Phase 2 Deprovisioning Script: Delete Users Past Grace Period
"""

import os.path
import re
import logging
import configargparse
from datetime import datetime
from dateutil.relativedelta import relativedelta
from pathlib import Path

from lib.ucs import Ucs


def parse_args():
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
        "--identity_provider",
        env_var="IDENTITY_PROVIDER",
        default="saml-umr",
        help="Keycloak identity provider alias (for consistency with other scripts).",
    )
    p.add(
        "--grace_period_months",
        env_var="GRACE_PERIOD_MONTHS",
        default=12,
        type=int,
        help="Grace period in months before permanent deletion (default: 12, ~365 days).",
    )
    p.add(
        "--loglevel",
        env_var="LOGLEVEL",
        default="INFO",
        help="Set the loglevel: DEBUG, INFO, WARNING, ERROR, CRITICAL.",
    )
    p.add("--logpath", env_var="LOGPATH", default="./logs", help="Path for log files.")
    p.add(
        "--output_deleted_filename",
        env_var="OUTPUT_DELETED_FILENAME",
        required=False,
        help="Output file for deleted users. Default: deleted-{domain}-{timestamp}.txt",
    )
    p.add(
        "--dry_run",
        env_var="DRY_RUN",
        default=False,
        type=lambda x: x.lower() in ("true", "1", "yes"),
        help="If True, only log what would be done without making changes.",
    )
    p.add(
        "--verify_certificate",
        env_var="VERIFY_CERTIFICATE",
        default=True,
        type=lambda x: x.lower() in ("true", "1", "yes"),
        help="Verify SSL certificates.",
    )
    p.add(
        "--enforce_ipv4",
        env_var="ENFORCE_IPV4",
        default=False,
        type=lambda x: x.lower() in ("true", "1", "yes"),
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


def setup_logging(options):
    Path(options.logpath).mkdir(parents=True, exist_ok=True)

    logFormatter = logging.Formatter("%(asctime)s %(levelname)-5.5s %(message)s")
    rootLogger = logging.getLogger()
    rootLogger.setLevel(options.loglevel)

    fileHandler = logging.FileHandler(
        f"{options.logpath}/{os.path.basename(__file__)}.log"
    )
    fileHandler.setFormatter(logFormatter)
    rootLogger.addHandler(fileHandler)

    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(logFormatter)
    rootLogger.addHandler(consoleHandler)

    logging.info("Running with settings:")
    for option, setting in vars(options).items():
        if "password" in option.lower():
            logging.info(f"> {option}: <redacted>")
        else:
            logging.info(f"> {option}: {setting}")


def parse_deprovision_timestamp(description):
    if not description:
        return None

    match = re.search(
        r"Deprovisioned on (\d{4}-\d{2}-\d{2}T\d{2}h\d{2}m\d{2}sZ)", description
    )

    if match:
        timestamp_str = match.group(1)
        try:
            return datetime.strptime(timestamp_str, "%Y-%m-%dT%Hh%Mm%SZ")
        except ValueError as e:
            logging.warning(f"Failed to parse timestamp '{timestamp_str}': {e}")
            return None

    return None


def get_deprovisioned_users(ucs):
    deprovisioned_users = []

    try:
        users = ucs._Ucs__get_object_list("user", "user")

        for user in users:
            dn = user.get("dn", "")
            if not dn.startswith("uid="):
                continue

            username = dn.split(",")[0].replace("uid=", "")

            properties = user.get("properties", {})
            description = properties.get("description", "")

            timestamp = parse_deprovision_timestamp(description)

            if timestamp:
                deprovisioned_users.append((username, timestamp))

        logging.info(f"Found {len(deprovisioned_users)} deprovisioned users in UCS")
        return deprovisioned_users

    except Exception as e:
        logging.error(f"Failed to get deprovisioned users: {e}")
        return []


def is_past_grace_period(deprovision_timestamp, grace_period_months):
    cutoff_date = datetime.now() - relativedelta(months=grace_period_months)
    return deprovision_timestamp < cutoff_date


def delete_user_and_admin(ucs, username, dry_run=False):
    success = True

    if dry_run:
        logging.info(f"  [DRY RUN] Would delete user {username}")
        return True

    logging.info(f"  Deleting user {username}...")
    if ucs.delete_user(username):
        logging.info(f"  Deleted user {username}")
    else:
        logging.error(f"  Failed to delete user {username}")
        success = False

    admin_username = f"{username}-admin"
    logging.info(f"  Checking for admin account {admin_username}...")
    if ucs.delete_user(admin_username):
        logging.info(f"  Deleted admin account {admin_username}")
    else:
        logging.debug(f"  Admin account {admin_username} not found or already deleted")

    return success


def main():
    options = parse_args()
    setup_logging(options)

    timestamp = datetime.now().strftime("%Y-%m-%dT%Hh%Mm%SZ")

    if options.output_deleted_filename:
        output_file = options.output_deleted_filename
    else:
        output_file = f"deleted-{options.import_domain}-{timestamp}.txt"

    maildomain = options.import_maildomain or options.import_domain

    class UcsOptions:
        pass

    ucs_options = UcsOptions()
    ucs_options.enforce_ipv4 = options.enforce_ipv4
    ucs_options.localhost_port = options.localhost_port
    ucs_options.verify_certificate = options.verify_certificate
    ucs_options.output_accounts_filename = None
    ucs_options.reconcile_groups = False
    ucs_options.trigger_invitation_mail = False
    ucs_options.create_maildomains = False
    ucs_options.create_oxcontexts = False
    ucs_options.default_oxcontext = 1
    ucs_options.group_component_enable_groupware = True
    ucs_options.group_component_enable_fileshare = True
    ucs_options.group_component_enable_projectmanagement = True
    ucs_options.group_component_enable_knowledgemanagement = True
    ucs_options.group_component_enable_livecollaboration = True
    ucs_options.group_component_enable_videoconference = True
    ucs_options.group_component_enable_notes = True
    ucs_options.component_disable_groupware = False
    ucs_options.component_disable_fileshare = False
    ucs_options.component_disable_projectmanagement = False
    ucs_options.component_disable_knowledgemanagement = False
    ucs_options.component_disable_livecollaboration = False
    ucs_options.component_disable_videoconference = False
    ucs_options.component_disable_notes = False
    ucs_options.admin_enable_fileshare = False
    ucs_options.admin_enable_projectmanagement = False
    ucs_options.admin_enable_knowledgemanagement = False

    ucs = Ucs(
        adm_username=options.udm_api_username,
        adm_password=options.udm_api_password,
        base_url=options.import_domain,
        maildomain=maildomain,
        options_object=ucs_options,
    )

    deprovisioned_users = get_deprovisioned_users(ucs)

    if not deprovisioned_users:
        logging.info("No deprovisioned users found.")
        return

    users_to_delete = []
    users_within_grace = []

    for username, deprovision_ts in deprovisioned_users:
        if is_past_grace_period(deprovision_ts, options.grace_period_months):
            users_to_delete.append((username, deprovision_ts))
        else:
            users_within_grace.append((username, deprovision_ts))

    logging.info(f"Users to delete (past grace period): {len(users_to_delete)}")
    logging.info(f"Users within grace period: {len(users_within_grace)}")

    for username, deprovision_ts in users_within_grace:
        logging.debug(f"  Within grace: {username} (deprovisioned: {deprovision_ts})")

    if not users_to_delete:
        logging.info("No users past grace period to delete.")
        return

    deleted_count = 0
    failed_count = 0

    for username, deprovision_ts in sorted(users_to_delete, key=lambda x: x[1]):
        logging.info(f"Processing {username} (deprovisioned: {deprovision_ts})")

        if delete_user_and_admin(ucs, username, dry_run=options.dry_run):
            deleted_count += 1

            with open(output_file, "a") as f:
                f.write(f"{username}\t{deprovision_ts}\t{timestamp}\n")
        else:
            failed_count += 1

    logging.info("=" * 50)
    logging.info("Deletion Summary:")
    logging.info(f"  Users deleted: {deleted_count}")
    logging.info(f"  Failed: {failed_count}")
    logging.info(f"  Within grace period: {len(users_within_grace)}")
    logging.info(f"  Output file: {output_file}")
    ucs.summary()


if __name__ == "__main__":
    main()
