#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

"""
Common utilities shared across user import scripts.
"""

import inspect
import logging
import os.path
from pathlib import Path
from typing import Any
from datetime import datetime


def parse_bool_string(x: str) -> bool:
    """Parse boolean from string values like 'true', '1', 'yes'."""
    return x.lower() in ("true", "1", "yes")


def setup_logging(options: Any, script_name: str | None = None) -> None:
    """
    Configure logging with file and console handlers.

    Args:
        options: Object with logpath and loglevel attributes.
                 Also iterates over all attributes for logging.
        script_name: Name of the script (for log file name).
                    If None, attempts to determine from caller's filename.
    """
    Path(options.logpath).mkdir(parents=True, exist_ok=True)

    logFormatter = logging.Formatter("%(asctime)s %(levelname)-5.5s %(message)s")
    rootLogger = logging.getLogger()
    rootLogger.setLevel(options.loglevel)

    # Determine log file name
    if script_name is None:
        # Use inspect to get the calling module's filename
        try:
            caller_frame = inspect.stack()[1]
            script_name = os.path.basename(caller_frame.filename)
        except (IndexError, AttributeError):
            script_name = "unknown.log"

    fileHandler = logging.FileHandler("{0}/{1}.log".format(options.logpath, script_name))
    fileHandler.setFormatter(logFormatter)
    rootLogger.addHandler(fileHandler)

    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(logFormatter)
    rootLogger.addHandler(consoleHandler)

    logging.info("Running with settings:")
    for option, setting in vars(options).items():
        logging.info(f"> {option}: {setting if 'password' not in option else '<redacted>'}")


def create_ucs_options(
    enforce_ipv4: bool = False,
    localhost_port: int | None = None,
    verify_certificate: bool = True,
    output_accounts_filename: str | None = None,
    reconcile_groups: bool = False,
    trigger_invitation_mail: bool = False,
    create_maildomains: bool = False,
    create_oxcontexts: bool = False,
    default_oxcontext: int = 1,
) -> Any:
    """
    Create a default Ucs options object with standard defaults.

    Args:
        enforce_ipv4: Force IPv4 communication.
        localhost_port: Port for localhost tunneling.
        verify_certificate: Verify SSL certificates.
        output_accounts_filename: File to write account credentials.
        reconcile_groups: Reconcile user groups.
        trigger_invitation_mail: Send invitation mail.
        create_maildomains: Auto-create mail domains.
        create_oxcontexts: Auto-create OX contexts.
        default_oxcontext: Default OX context ID.

    Returns:
        A simple object with all Ucs configuration options.
    """

    class UcsOptions:
        pass

    ucs_options = UcsOptions()
    ucs_options.enforce_ipv4 = enforce_ipv4
    ucs_options.localhost_port = localhost_port
    ucs_options.verify_certificate = verify_certificate
    ucs_options.output_accounts_filename = output_accounts_filename
    ucs_options.reconcile_groups = reconcile_groups
    ucs_options.trigger_invitation_mail = trigger_invitation_mail
    ucs_options.create_maildomains = create_maildomains
    ucs_options.create_oxcontexts = create_oxcontexts
    ucs_options.default_oxcontext = default_oxcontext

    # Group component settings (all enabled by default)
    ucs_options.group_component_enable_groupware = True
    ucs_options.group_component_enable_fileshare = True
    ucs_options.group_component_enable_projectmanagement = True
    ucs_options.group_component_enable_knowledgemanagement = True
    ucs_options.group_component_enable_livecollaboration = True
    ucs_options.group_component_enable_videoconference = True
    ucs_options.group_component_enable_notes = True

    # Component disable settings (all False by default)
    ucs_options.component_disable_groupware = False
    ucs_options.component_disable_fileshare = False
    ucs_options.component_disable_projectmanagement = False
    ucs_options.component_disable_knowledgemanagement = False
    ucs_options.component_disable_livecollaboration = False
    ucs_options.component_disable_videoconference = False
    ucs_options.component_disable_notes = False

    # Admin enable settings (all False by default)
    ucs_options.admin_enable_fileshare = False
    ucs_options.admin_enable_projectmanagement = False
    ucs_options.admin_enable_knowledgemanagement = False

    return ucs_options


def get_timestamp() -> str:
    """
    Get a formatted timestamp for use in filenames and logs.

    Returns:
        Timestamp string in format: YYYY-MM-DDTHHhMMmSSZ
    """
    return datetime.now().strftime("%Y-%m-%dT%Hh%Mm%SZ")


def get_default_output_filename(prefix: str, domain: str) -> str:
    """
    Get a default output filename with timestamp.

    Args:
        prefix: Prefix for the filename (e.g., 'users', 'deprovisioned', 'deleted').
        domain: Domain name to include in filename.

    Returns:
        Filename in format: {prefix}-{domain}-{timestamp}.txt
    """
    timestamp = get_timestamp()
    return f"{prefix}-{domain}-{timestamp}.txt"
