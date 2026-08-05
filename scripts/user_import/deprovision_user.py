#!/usr/bin/env python3
"""
User Deprovisioning for openDesk Edu
Two-phase deprovisioning: disable → archive → delete
"""

import argparse
import logging
import os
import sys
from datetime import datetime, timedelta
from typing import Dict

from sync_users import KeycloakAdminClient

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("/var/log/opendesk-user-deprovisioning.log"), logging.StreamHandler()],
)
logger = logging.getLogger(__name__)


class UserDeprovisioner:
    """Handles user deprovisioning lifecycle"""

    def __init__(self) -> None:
        self.keycloak_client = KeycloakAdminClient()
        self.grace_period_days = int(os.getenv("GRACE_PERIOD_DAYS", "180"))

    def deprovision_user(
        self, username: str, phase: str = "disable", dry_run: bool = False, reason: str = None
    ) -> bool:
        """
        Deprovision user in two phases

        Phase 1 (disable): Disable account, revoke access
        Phase 2 (delete): Permanently remove user and data

        Args:
            username: Username to deprovision
            phase: 'disable' or 'delete'
            dry_run: Show what would happen without changes
            reason: Reason for deprovisioning
        """
        try:
            user = self.keycloak_client.get_user(username)
            if not user:
                logger.error(f"User {username} not found")
                return False

            if phase == "disable":
                return self._disable_user(user, dry_run, reason)
            elif phase == "delete":
                return self._delete_user(user, dry_run)
            else:
                logger.error(f"Invalid phase: {phase}")
                return False

        except Exception as e:
            logger.error(f"Failed to deprovision user {username}: {e}")
            return False

    def _disable_user(self, user: Dict, dry_run: bool, reason: str = None) -> bool:
        """Phase 1: Disable user account"""
        username = user["username"]

        try:
            # Log the action
            log_message = f"Deprovisioning user: {username}"
            if reason:
                log_message += f" (reason: {reason})"
            logger.info(log_message)

            # Disable user
            if not self.keycloak_client.disable_user(username, dry_run):
                return False

            # Store deprovisioning metadata
            self._store_deprovisioning_metadata(user, phase="disable", reason=reason, dry_run=dry_run)

            # Revoke active sessions
            if not dry_run:
                self.keycloak_client.admin.delete_user_sessions(user["id"])
                logger.info(f"Revoked all sessions for {username}")

            logger.warning(f"User {username} DISABLED (grace period: {self.grace_period_days} days)")
            return True

        except Exception as e:
            logger.error(f"Failed to disable user {username}: {e}")
            return False

    def _delete_user(self, user: Dict, dry_run: bool) -> bool:
        """Phase 2: Permanently delete user"""
        username = user["username"]

        try:
            # Verify grace period has passed
            if not self._grace_period_expired(user) and not dry_run:
                logger.error(f"Grace period has not expired for {username}, cannot delete yet")
                return False

            logger.warning(f"Permanently DELETING user: {username}")

            # Archive user data before deletion
            if not dry_run:
                self._archive_user_data(user)

            # Delete user
            if not self.keycloak_client.delete_user(username, dry_run):
                return False

            # Store final deprovisioning metadata
            self._store_deprovisioning_metadata(user, phase="delete", dry_run=dry_run)

            logger.warning(f"User {username} PERMANENTLY DELETED")
            return True

        except Exception as e:
            logger.error(f"Failed to delete user {username}: {e}")
            return False

    def _store_deprovisioning_metadata(
        self, user: Dict, phase: str, reason: str | None = None, dry_run: bool = False
    ) -> None:
        """Store deprovisioning audit metadata"""
        if dry_run:
            logger.info(f"[DRY RUN] Would store deprovisioning metadata for {user['username']}")
            return

        # Implementation: write to audit log or database
        audit_data = {
            "username": user["username"],
            "user_id": user["id"],
            "email": user.get("email"),
            "phase": phase,
            "timestamp": datetime.now().isoformat(),
            "reason": reason or "none",
            "attributes": {
                "affiliation": user.get("attributes", {}).get("affiliation", ["unknown"])[0]
                if "attributes" in user
                else "unknown"
            },
        }

        # Write to audit file
        audit_dir = "/var/log/opendesk-audit"
        os.makedirs(audit_dir, exist_ok=True)
        audit_file = os.path.join(audit_dir, f"deprovisioning-{datetime.now().strftime('%Y%m%d')}.log")

        with open(audit_file, "a") as f:
            f.write(
                f"{datetime.now().isoformat()} | {audit_data['phase']} | {audit_data['username']} | {audit_data['reason']}\n"
            )

        logger.info(f"Stored deprovisioning metadata for {user['username']}")

    def _archive_user_data(self, user: Dict) -> None:
        """Archive user data from all services before deletion"""
        username = user["username"]

        try:
            # Use service archiver to archive from all services
            from archive_service_user import ServiceArchiver

            archiver = ServiceArchiver()

            logger.info(f"Starting service-wide archive for {username}")
            archives = archiver.archive_user(username)

            if archives:
                logger.info(f"Archived data from {len(archives)} services for {username}")

                # Create combined tarball
                complete_archive = archiver.compress_all_archives(username)
                if complete_archive:
                    logger.info(f"Complete archive: {complete_archive}")
            else:
                logger.warning(f"No service archives created for {username}")

        except ImportError:
            logger.warning("Service archiver not available, skipping service archives")
            # Fall back to simple Keycloak-only archive
            self._fallback_archive(user)
        except Exception as e:
            logger.error(f"Failed to archive service data for {username}: {e}")
            # Attempt fallback archive
            self._fallback_archive(user)

    def _fallback_archive(self, user: Dict) -> None:
        """Fallback to simple Keycloak-only archive if service archiver fails"""
        username = user["username"]

        try:
            # Create archive directory
            archive_dir = "/var/lib/opendesk-archives"
            os.makedirs(archive_dir, exist_ok=True)

            # Create user-specific archive
            user_archive_dir = os.path.join(archive_dir, username, datetime.now().strftime("%Y%m%d"))
            os.makedirs(user_archive_dir, exist_ok=True)

            # Export user data
            import json

            user_data_file = os.path.join(user_archive_dir, "user-data.json")
            with open(user_data_file, "w") as f:
                json.dump(user, f, indent=2)

            logger.info(f"Archived Keycloak user data for {username} to {user_archive_dir}")

        except Exception as e:
            logger.error(f"Fallback archive failed for {username}: {e}")

    def _grace_period_expired(self, user: Dict) -> bool:
        """Check if grace period has expired for a disabled user"""
        try:
            # Check when user was disabled
            if "attributes" in user and "disabled_at" in user["attributes"]:
                disabled_at = datetime.fromisoformat(user["attributes"]["disabled_at"][0])
                expiry_date = disabled_at + timedelta(days=self.grace_period_days)
                return datetime.now() >= expiry_date

            # If no timestamp, assume expired for safety
            return True

        except Exception as e:
            logger.warning(f"Could not determine grace period: {e}")
            # Fail safe: assume expired
            return True

    def deprovision_batch(
        self, input_file: str, phase: str = "disable", dry_run: bool = False, confirm: bool = False
    ) -> Dict[str, int]:
        """Deprovision users from a batch file"""
        if not confirm and not dry_run:
            print(f"This will {phase} users from {input_file}")
            print("Continue? (yes/no): ", end="")
            response = input().strip().lower()
            if response != "yes":
                print("Cancelled")
                return {}

        stats = {"success": 0, "failed": 0, "skipped": 0}

        try:
            with open(input_file, "r") as f:
                usernames = [line.strip() for line in f if line.strip()]

            logger.info(f"Starting batch deprovisioning of {len(usernames)} users")
            logger.info(f"Phase: {phase}, Dry run: {dry_run}")

            for username in usernames:
                if self.deprovision_user(username, phase=phase, dry_run=dry_run):
                    stats["success"] += 1
                else:
                    stats["failed"] += 1

        except Exception as e:
            logger.error(f"Batch deprovisioning failed: {e}")

        return stats

    def deprovision_by_filter(
        self, filter_func: callable, phase: str = "disable", dry_run: bool = False
    ) -> Dict[str, int]:
        """Deprovision users matching a filter function"""
        stats = {"success": 0, "failed": 0, "skipped": 0}

        try:
            users = self.keycloak_client.admin.get_users({"enabled": True})
            logger.info(f"Checking {len(users)} enabled users for deprovisioning")

            for user in users:
                if filter_func(user):
                    if self.deprovision_user(user["username"], phase=phase, dry_run=dry_run):
                        stats["success"] += 1
                    else:
                        stats["failed"] += 1

        except Exception as e:
            logger.error(f"Filter-based deprovisioning failed: {e}")

        return stats


def create_ruckmeldung_filter(no_ruckmeldung_since: str) -> callable:
    """Create filter function for students who haven't re-registered"""
    cutoff_date = datetime.strptime(no_ruckmeldung_since, "%Y-%m-%d")

    def filter_func(user: Dict) -> bool:
        try:
            if "attributes" in user and "last_ruckmeldung" in user["attributes"]:
                last_ruckmeldung = datetime.fromisoformat(user["attributes"]["last_ruckmeldung"][0])
                return last_ruckmeldung < cutoff_date
            return False
        except Exception:
            return False

    return filter_func


def main() -> None:
    parser = argparse.ArgumentParser(description="Deprovision users from Keycloak")
    parser.add_argument("username", nargs="?", help="Username to deprovision")
    parser.add_argument(
        "--phase",
        choices=["disable", "delete"],
        default="disable",
        help="Deprovisioning phase: disable (grace period) or delete (permanent)",
    )
    parser.add_argument("--grace-period-days", type=int, default=None, help="Override grace period in days")
    parser.add_argument("--reason", help="Reason for deprovisioning")
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen without making changes")
    parser.add_argument("--input-file", help="Batch deprovision from CSV file")
    parser.add_argument("--confirm", action="store_true", help="Skip confirmation prompt for batch operations")
    parser.add_argument("--filter", choices=["no-ruckmeldung"], help="Deprovision by filter criteria")
    parser.add_argument("--no-ruckmeldung-since", help="Disable students who haven't re-registered since (YYYY-MM-DD)")
    parser.add_argument("--grace-expired-before", help="Delete users whose grace period expired before (YYYY-MM-DD)")

    args = parser.parse_args()

    dry_run = os.getenv("DRY_RUN", "false").lower() == "true" or args.dry_run

    logger.info(f"Starting user deprovisioning (phase={args.phase}, dry_run={dry_run})")

    # Initialize deprovisioner
    deprovisioner = UserDeprovisioner()

    if not deprovisioner.keycloak_client.connect():
        logger.error("Failed to connect to Keycloak, exiting")
        sys.exit(1)

    # Override grace period if specified
    if args.grace_period_days:
        deprovisioner.grace_period_days = args.grace_period_days

    stats = {}

    # Single user deprovisioning
    if args.username:
        if deprovisioner.deprovision_user(args.username, phase=args.phase, dry_run=dry_run, reason=args.reason):
            stats["success"] = 1
        else:
            stats["failed"] = 1

    # Batch deprovisioning from file
    elif args.input_file:
        stats = deprovisioner.deprovision_batch(
            args.input_file, phase=args.phase, dry_run=dry_run, confirm=args.confirm
        )

    # Filter-based deprovisioning
    elif args.filter == "no-ruckmeldung" and args.no_ruckmeldung_since:
        filter_func = create_ruckmeldung_filter(args.no_ruckmeldung_since)
        stats = deprovisioner.deprovision_by_filter(filter_func, phase=args.phase, dry_run=dry_run)

    # Grace period expired users
    elif args.grace_expired_before and args.phase == "delete":
        datetime.strptime(args.grace_expired_before, "%Y-%m-%d")

        def grace_filter(user: Dict) -> bool:
            return deprovisioner._grace_period_expired(user)

        stats = deprovisioner.deprovision_by_filter(grace_filter, phase="delete", dry_run=dry_run)

    else:
        logger.error("No action specified. --username, --input-file, or --filter required")
        sys.exit(1)

    # Print statistics
    logger.info("Deprovisioning complete:")
    logger.info(f"  Success: {stats.get('success', 0)}")
    logger.info(f"  Failed: {stats.get('failed', 0)}")
    logger.info(f"  Skipped: {stats.get('skipped', 0)}")


if __name__ == "__main__":
    main()
