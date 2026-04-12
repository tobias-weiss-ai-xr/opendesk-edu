#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

import os.path
import secrets
import logging
from typing import Any, Dict
import configargparse

from pathlib import Path

from lib.argparse_types import opt2bool
from lib.constants import NON_RECONCILE_GROUPS, DEFAULT_IDENTITY_PROVIDER
from lib.ucs import Ucs
from lib.random_user import RandomUser
from lib.import_user import ImportUser

p = configargparse.ArgParser()
p.add(
    "--admin_enable_fileshare",
    env_var="ADMIN_ENABLE_FILESHARE",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should get functional admin permissions for fileshare component.',
)
p.add(
    "--admin_enable_knowledgemanagement",
    env_var="ADMIN_ENABLE_KNOWLEDGEMANAGEMENT",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should get functional admin permissions for knowledgemanagement component.',
)
p.add(
    "--admin_enable_projectmanagement",
    env_var="ADMIN_ENABLE_PROJECTMANAGEMENT",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should get functional admin permissions for projectmanagement component.',
)
p.add(
    "--component_disable_fileshare",
    env_var="COMPONENT_DISABLE_FILESHARE",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should not get the flag for fileshare access.',
)
p.add(
    "--component_disable_groupware",
    env_var="COMPONENT_DISABLE_GROUPWARE",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should not get the flag for groupware access.',
)
p.add(
    "--component_disable_knowledgemanagement",
    env_var="COMPONENT_DISABLE_KNOWLEDGEMANAGEMENT",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should not get the flag for knowledgemanagement access.',
)
p.add(
    "--component_disable_livecollaboration",
    env_var="COMPONENT_DISABLE_LIVECOLLABORATION",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should not get the flag for livecollaboration access.',
)
p.add(
    "--component_disable_projectmanagement",
    env_var="COMPONENT_DISABLE_PROJECTMANAGEMENT",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should not get the flag for projectmanagement access.',
)
p.add(
    "--component_disable_videoconference",
    env_var="COMPONENT_DISABLE_VIDEOCONFERENCE",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should not get the flag for videoconference access.',
)
p.add(
    "--component_disable_notes",
    env_var="COMPONENT_DISABLE_NOTES",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if users should not get the flag for notes access.',
)
p.add(
    "--group_component_enable_fileshare",
    env_var="GROUP_COMPONENT_ENABLE_FILESHARE",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if groups should be accessible by fileshare',
)
p.add(
    "--group_component_enable_projectmanagement",
    env_var="GROUP_COMPONENT_ENABLE_PROJECTMANAGEMENT",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if groups should be accessible by project management',
)
p.add(
    "--group_component_enable_knowledgemanagement",
    env_var="GROUP_COMPONENT_ENABLE_KNOWLEDGEMANAGEMENT",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if groups should be accessible by knowledge management',
)
p.add(
    "--create_admin_accounts",
    env_var="CREATE_ADMIN_ACCOUNTS",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if each user also should get an additional "<username>-admin" account',
)
p.add(
    "--create_maildomains",
    env_var="CREATE_MAILDOMAINS",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" to get non existing mail domains auto-created. Only relevant when importing a files in which mailPrimaryAddresses are provided that differ from the default (mail)domain.',
)
p.add(
    "--create_oxcontexts",
    env_var="CREATE_OXCONTEXT",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" to get non-existing OX contexts auto-created.',
)
p.add(
    "--default_oxcontext",
    env_var="DEFAULT_OXCONTEXT",
    default=1,
    type=int,
    help="Optional: Set the default OX context ID to use when creating users. Default: 1",
)
p.add(
    "--import_domain",
    env_var="IMPORT_DOMAIN",
    required=True,
    help='The domain name of your openDesk instance - omit the "portal." or other service specific hostnames.',
)
p.add(
    "--import_filename",
    env_var="IMPORT_FILENAME",
    required=False,
    help="The filename containing the user account details for the import - see template.ods for reference. If filename is not provided or related file is not found random users will be imported.",
)
p.add(
    "--import_use_images",
    env_var="IMPORT_USE_IMAGES",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if each user should be uploaded with a random profile picture when "import_filename" was set.',
)
p.add(
    "--import_maildomain",
    env_var="IMPORT_MAILDOMAIN",
    required=False,
    help="Optional: If you are using a different maildomain please specify it, otherwise `IMPORT_DOMAIN` is used.",
)
p.add(
    "--import_random_amount",
    env_var="IMPORT_RANDOM_AMOUNT",
    default=10,
    type=int,
    help='The number of random accounts to import if the "import_filename" was not set or found.',
)
p.add(
    "--import_random_usernames",
    env_var="IMPORT_RANDOM_USERNAMES",
    default=True,
    type=opt2bool,
    help='If set to "False" the imported usernames of the imported follow the format user.N and admin.N.',
)
p.add(
    "--localhost_port",
    env_var="LOCALHOST_PORT",
    default=None,
    type=int,
    help="Provide port number for localhost connections (that tunnel to a remote UDM REST API)",
)
p.add(
    "--enforce_ipv4",
    env_var="ENFORCE_IPV4",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" to enforce IPv4 communication - helps when IPv6 is causing issues, e.g. requests taking minutes to get processed.',
)
p.add(
    "--loglevel",
    env_var="LOGLEVEL",
    default="INFO",
    help="Set the loglevel: DEBUG, INFO, WARNING, ERROR, CRITICAL. Default: WARNING",
)
p.add(
    "--logpath",
    env_var="LOGPATH",
    default="./logs",
    help="Path where the script write its logfile to. Default: ./logs",
)
p.add(
    "--output_accounts_filename",
    env_var="OUTPUT_ACCOUNTS_FILENAME",
    required=False,
    help='The filename to write the created accounts (username<tab>password) into, appends if file exists). If none is provided the default name will be "users-<import_domain>-<timestamp>.txt"',
)
p.add(
    "--password_recovery_email",
    env_var="PASSWORD_RECOVERY_EMAIL",
    help="Optional: When creating random accounts this password recovery email is used.",
)
p.add(
    "--reconcile_groups",
    env_var="RECONCILE_GROUPS",
    default=False,
    type=opt2bool,
    help=f'Optional: Set to "True" if groups on the users should be reconciled based on the input file. Will remove all groups from the user not defined in sheet except for the standard groups: {"; ".join(NON_RECONCILE_GROUPS)}',
)
p.add(
    "--set_default_password",
    env_var="SET_DEFAULT_PASSWORD",
    default="",
    help="Optional: When set the given password is used on the newly created accounts, otherwise a random one will be created.",
)
p.add(
    "--trigger_invitation_mail",
    env_var="TRIGGER_INVITATION_MAIL",
    default=False,
    type=opt2bool,
    help='Optional: Set to "True" if you want invitation mail (same as password recovery mail) being trigger for each created user.',
)
p.add(
    "--udm_api_password",
    env_var="UDM_API_PASSWORD",
    required=True,
    help="Password for the UDM REST API user.",
)
p.add(
    "--udm_api_username",
    env_var="UDM_API_USERNAME",
    default="Administrator",
    help="User to authentication against the UDM REST API with.",
)
p.add(
    "--verify_certificate",
    env_var="VERIFY_CERTIFICATE",
    default=True,
    type=opt2bool,
    help='Optional: DEV MODE ONLY - NEVER USE THIS IN PRODUCTION SCENARIO: Set to "False" to skip certificate check on the API calls.',
)
p.add(
    "--iam_api_url",
    env_var="IAM_API_URL",
    default=None,
    help="IAM API URL to fetch user data from. If set, users are loaded from this API instead of a file.",
)
p.add(
    "--keycloak_url",
    env_var="KEYCLOAK_URL",
    default=None,
    help="Keycloak base URL (e.g. https://id.example.com) for SAML identity linking.",
)
p.add(
    "--keycloak_api_username",
    env_var="KEYCLOAK_API_USERNAME",
    default=None,
    help="Keycloak admin username for SAML identity linking.",
)
p.add(
    "--keycloak_api_password",
    env_var="KEYCLOAK_API_PASSWORD",
    default=None,
    help="Keycloak admin password for SAML identity linking.",
)
p.add(
    "--identity_provider",
    env_var="IDENTITY_PROVIDER",
    default=DEFAULT_IDENTITY_PROVIDER,
    help=f"Keycloak identity provider alias for SAML linking. Default: {DEFAULT_IDENTITY_PROVIDER}",
)

options = p.parse_args()

new_user_password = options.set_default_password

Path(options.logpath).mkdir(parents=True, exist_ok=True)

logFormatter = logging.Formatter("%(asctime)s %(levelname)-5.5s %(message)s")
rootLogger = logging.getLogger()
rootLogger.setLevel(options.loglevel)

fileHandler = logging.FileHandler("{0}/{1}.log".format(options.logpath, os.path.basename(__file__)))
fileHandler.setFormatter(logFormatter)
rootLogger.addHandler(fileHandler)

consoleHandler = logging.StreamHandler()
consoleHandler.setFormatter(logFormatter)
rootLogger.addHandler(consoleHandler)

logging.info("Running with settings:")
for option, setting in vars(options).items():
    logging.info(f"> {option}: {setting if 'password' not in option else '<redacted>'}")


def import_callback(person: Dict[str, Any]) -> None:
    global new_user_password
    if "password" in person and len(str(person["password"])) >= 8:
        logging.debug("Using predefined password for user.")
    elif new_user_password is None or len(new_user_password) < 8:
        person["password"] = "".join(
            (secrets.choice('öäüÄÖÜß-+<>".,;:0123456789!$%&/()=[]{}<>|_#+*~?') for _ in range(16))
        )
    else:
        person["password"] = new_user_password
    ucs.set_user(person)


import_maildomain = options.import_domain if not options.import_maildomain else options.import_maildomain

ucs = Ucs(
    adm_username=options.udm_api_username,
    adm_password=options.udm_api_password,
    base_url=options.import_domain,
    maildomain=import_maildomain,
    options_object=options,
)

if not options.import_filename and not options.iam_api_url:
    logging.info("Starting random user import, as no file for import was defined.")
    RandomUser(
        import_callback,
        create_admin_accounts=options.create_admin_accounts,
        amount=options.import_random_amount,
        password_reset_mail=options.password_recovery_email,
        randomize_username=options.import_random_usernames,
    )
    logging.info(f"Accounts that have been created:\n{ucs.get_imported_credentials_list()}")
elif options.iam_api_url:
    logging.info(f"Importing users from IAM API: {options.iam_api_url}")
    ImportUser(
        import_callback,
        iam_api_url=options.iam_api_url,
        create_admin_accounts=options.create_admin_accounts,
        use_images=options.import_use_images,
        password_recovery_email=options.password_recovery_email,
        keycloak_url=options.keycloak_url,
        keycloak_username=options.keycloak_api_username,
        keycloak_password=options.keycloak_api_password,
        identity_provider=options.identity_provider,
    )
elif os.path.isfile(options.import_filename):
    logging.info(f"Importing users from '{options.import_filename}'")
    ImportUser(
        import_callback,
        import_filename=options.import_filename,
        create_admin_accounts=options.create_admin_accounts,
        use_images=options.import_use_images,
        password_recovery_email=options.password_recovery_email,
        keycloak_url=options.keycloak_url,
        keycloak_username=options.keycloak_api_username,
        keycloak_password=options.keycloak_api_password,
        identity_provider=options.identity_provider,
    )
else:
    logging.error(f"File to import from '{options.import_filename}' was not found.")

ucs.summary()
