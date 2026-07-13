#!/usr/bin/env python3
"""Guest lecturer account cleanup CronJob.

Scans Keycloak for guest lecturer accounts (attributes.guestLecturer=true)
with expiry dates. Disables expired accounts and removes group memberships.

ENV vars:
  KEYCLOAK_URL, KEYCLOAK_REALM, KEYCLOAK_CLIENT_ID, KEYCLOAK_CLIENT_SECRET
"""

from __future__ import annotations

import os
import sys
import logging
from datetime import datetime
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sync.keycloak_client import KeycloakClient, KeycloakConfig

logger = logging.getLogger("guest_cleanup")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")


def process_guest_cleanup(dry_run: bool = False) -> dict[str, Any]:
    """Find and disable expired guest lecturer accounts.
    
    Returns summary dict with disabled count and warnings.
    """
    kc = KeycloakClient(KeycloakConfig.from_env())
    now = datetime.utcnow()
    warning_days = 14  # Warn when within 14 days of expiry
    
    summary = {"expired_and_disabled": 0, "expiring_soon_warned": 0, "errors": 0, "expiring_soon": []}
    
    resp = kc._request("GET", "/users?q=guestLecturer:true&max=50000")
    guest_users = resp.json()
    
    logger.info(f"Found {len(guest_users)} guest lecturer accounts")
    
    for user in guest_users:
        user_id = user["id"]
        username = user.get("username", "")
        attrs = user.get("attributes") or {}
        expiry_str = (attrs.get("accountExpiry") or [None])[0]
        
        if not expiry_str:
            continue
        
        try:
            expiry = datetime.fromisoformat(expiry_str)
        except (ValueError, TypeError):
            logger.warning(f"Invalid expiry date for {username}: {expiry_str}")
            continue
        
        days_until_expiry = (expiry - now).days
        
        if days_until_expiry <= 0:
            if not dry_run:
                try:
                    current_groups = kc.list_user_groups(user_id)
                    for group in current_groups:
                        kc.remove_group(user_id, group["id"])
                    
                    kc.disable_user(user_id)
                    logger.info(f"Disabled expired guest account: {username} (expired {expiry_str})")
                    summary["expired_and_disabled"] += 1
                except Exception as e:
                    logger.error(f"Failed to disable expired guest {username}: {e}")
                    summary["errors"] += 1
            else:
                logger.info(f"[DRY RUN] Would disable expired guest: {username} (expired {expiry_str})")
                summary["expired_and_disabled"] += 1
                
        elif days_until_expiry <= warning_days:
            logger.warning(f"Guest account {username} expiring in {days_until_expiry}d ({expiry_str})")
            summary["expiring_soon_warned"] += 1
            summary["expiring_soon"].append({"username": username, "expires": expiry_str, "days_left": days_until_expiry})
    
    logger.info(f"Guest cleanup complete: {summary}")
    return summary


if __name__ == "__main__":
    dry_run = os.environ.get("DRY_RUN", "false").lower() == "true"
    result = process_guest_cleanup(dry_run=dry_run)
    print(f"Results: {result}")
    sys.exit(1 if result.get("errors", 0) > 0 else 0)
