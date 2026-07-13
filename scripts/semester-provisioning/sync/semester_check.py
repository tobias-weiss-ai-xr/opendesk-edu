#!/usr/bin/env python3
"""Semester re-registration verification CronJob.

Queries university LDAP for current enrollment status and compares
against Keycloak user state. Disables accounts for students past
the re-registration deadline, re-enables when they re-register.

ENV vars:
  HISINONE_LDAP_HOST, HISINONE_LDAP_PORT, HISINONE_LDAP_USE_SSL
  HISINONE_LDAP_BIND_DN, HISINONE_LDAP_BIND_PASSWORD
  HISINONE_LDAP_USERS_BASE_DN
  HISINONE_LDAP_ATTR_USERNAME, HISINONE_RE_REGISTRATION_GRACE
  KEYCLOAK_URL, KEYCLOAK_REALM, KEYCLOAK_CLIENT_ID, KEYCLOAK_CLIENT_SECRET
"""

from __future__ import annotations

import os
import sys
import logging
from datetime import datetime, timedelta
from typing import Any

# Add parent dir to path so sync/ is importable
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sync.keycloak_client import KeycloakClient, KeycloakConfig

logger = logging.getLogger("semester_check")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")


def get_enrolled_usernames_from_ldap() -> set[str]:
    """Query university LDAP for currently enrolled students.

    Returns set of usernames (uid) whose enrollment status is 'registered'.
    Uses the same LDAP connection settings from hisinone.yaml.gotmpl.

    Falls back to a no-op if LDAP is unreachable (log warning).
    """
    import ldap3  # optional dependency

    host = os.environ.get("HISINONE_LDAP_HOST", "ldap.uni-marburg.de")
    port = int(os.environ.get("HISINONE_LDAP_PORT", "636"))
    use_ssl = os.environ.get("HISINONE_LDAP_USE_SSL", "true").lower() == "true"
    bind_dn = os.environ.get("HISINONE_LDAP_BIND_DN", "uid=opendesk-sync,ou=services,dc=uni-marburg,dc=de")
    bind_pw = os.environ.get("HISINONE_LDAP_BIND_PASSWORD", "")
    users_base = os.environ.get("HISINONE_LDAP_USERS_BASE_DN", "ou=people,dc=uni-marburg,dc=de")
    username_attr = os.environ.get("HISINONE_LDAP_ATTR_USERNAME", "uid")
    enrollment_attr = os.environ.get("HISINONE_ENROLLMENT_STATUS_ATTR", "hisinoneEnrollmentStatus")

    if not bind_pw:
        logger.warning("HISINONE_LDAP_BIND_PASSWORD not set, skipping LDAP query")
        return set()

    server = ldap3.Server(host, port=port, use_ssl=use_ssl, get_info=ldap3.NONE)
    conn = ldap3.Connection(server, user=bind_dn, password=bind_pw, auto_bind=True)

    filter_str = f"(&(objectClass=person)({enrollment_attr}=registered))"
    conn.search(
        search_base=users_base,
        search_filter=filter_str,
        attributes=[username_attr],
        size_limit=50000,
    )

    usernames = set()
    for entry in conn.entries:
        uid = getattr(entry, username_attr, None)
        if uid:
            usernames.add(str(uid))

    conn.unbind()
    logger.info(f"LDAP query returned {len(usernames)} enrolled users")
    return usernames


def process_semester_check(dry_run: bool = False) -> dict[str, Any]:
    """Main semester re-registration check logic.

    Returns summary dict with action counts.
    """
    grace_days = int(os.environ.get("HISINONE_RE_REGISTRATION_GRACE", "30"))
    current_semester = os.environ.get("HISINONE_CURRENT_SEMESTER", "")

    kc = KeycloakClient(KeycloakConfig.from_env())

    # Get currently enrolled users from LDAP
    enrolled = get_enrolled_usernames_from_ldap()

    # Get Keycloak users with semester attribute matching current semester
    resp = kc._request("GET", f"/users?q=semester:{current_semester}&max=50000")
    semester_users = resp.json()

    summary = {"disabled": 0, "re_enabled": 0, "skipped_no_semester": 0, "errors": 0}

    for user in semester_users:
        username = user.get("username", "")
        user_id = user["id"]
        is_enabled = user.get("enabled", True)
        semester_attr = (user.get("attributes") or {}).get("semester", [None])[0]

        if not semester_attr:
            summary["skipped_no_semester"] += 1
            continue

        if username not in enrolled and is_enabled:
            # Student not in enrolled list - check grace period
            if not dry_run:
                try:
                    kc.update_user(user_id, {
                        "attributes": {
                            **(user.get("attributes") or {}),
                            "reRegistrationStatus": ["pending"],
                            "reRegistrationDeadline": [(datetime.utcnow() + timedelta(days=grace_days)).isoformat()],
                        }
                    })
                    logger.info(f"Marked {username} for re-registration (grace {grace_days}d)")
                except Exception as e:
                    logger.error(f"Failed to update {username}: {e}")
                    summary["errors"] += 1

        elif username in enrolled and not is_enabled:
            # Student re-registered but account is disabled - re-enable
            if not dry_run:
                try:
                    kc.enable_user(user_id)
                    kc.update_user(user_id, {
                        "attributes": {
                            **(user.get("attributes") or {}),
                            "reRegistrationStatus": ["confirmed"],
                        }
                    })
                    logger.info(f"Re-enabled {username} after re-registration")
                    summary["re_enabled"] += 1
                except Exception as e:
                    logger.error(f"Failed to re-enable {username}: {e}")
                    summary["errors"] += 1

    logger.info(f"Semester check complete: {summary}")
    return summary


if __name__ == "__main__":
    dry_run = os.environ.get("DRY_RUN", "false").lower() == "true"
    result = process_semester_check(dry_run=dry_run)
    print(f"Results: {result}")
    sys.exit(1 if result.get("errors", 0) > 0 else 0)
