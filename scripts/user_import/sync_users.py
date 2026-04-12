#!/usr/bin/env python3
"""
User Provisioning for openDesk Edu
Syncs users from LDAP to Keycloak with automatic role assignment
"""

import argparse
import logging
import os
import sys
from typing import Dict, List, Optional

import ldap3
from keycloak import KeycloakAdmin

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("/var/log/opendesk-user-sync.log"), logging.StreamHandler()],
)
logger = logging.getLogger(__name__)


class LDAPClient:
    """LDAP client for querying users from university directory"""

    def __init__(self) -> None:
        self.server = os.getenv("LDAP_SERVER", "ldap://localhost")
        self.base_dn = os.getenv("LDAP_BASE_DN", "")
        self.bind_dn = os.getenv("LDAP_BIND_DN", "")
        self.bind_password = os.getenv("LDAP_BIND_PASSWORD", "")
        self.search_base = os.getenv("LDAP_USER_SEARCH_BASE", "")
        self.object_class = os.getenv("LDAP_USER_OBJECT_CLASS", "inetOrgPerson")
        self.username_attr = os.getenv("LDAP_USERNAME_ATTR", "uid")
        self.email_attr = os.getenv("LDAP_EMAIL_ATTR", "mail")
        self.first_name_attr = os.getenv("LDAP_FIRST_NAME_ATTR", "givenName")
        self.last_name_attr = os.getenv("LDAP_LAST_NAME_ATTR", "sn")
        self.conn = None

    def connect(self) -> bool:
        """Establish LDAP connection"""
        try:
            server = ldap3.Server(self.server, get_info=ldap3.ALL)
            self.conn = ldap3.Connection(server, user=self.bind_dn, password=self.bind_password, auto_bind=True)
            logger.info(f"Connected to LDAP server: {self.server}")
            return True
        except Exception as e:
            logger.error(f"LDAP connection failed: {e}")
            return False

    def search_users(self, filter_str: str = None) -> List[Dict]:
        """Search LDAP for users"""
        if not self.conn:
            if not self.connect():
                return []

        try:
            if filter_str:
                search_filter = f"(&(objectClass={self.object_class}){filter_str})"
            else:
                search_filter = f"(objectClass={self.object_class})"

            self.conn.search(
                search_base=self.search_base,
                search_filter=search_filter,
                attributes=[
                    self.username_attr,
                    self.email_attr,
                    self.first_name_attr,
                    self.last_name_attr,
                    "eduPersonAffiliation",
                    "eduPersonEntitlement",
                ],
            )

            users = []
            for entry in self.conn.entries:
                user = {}
                if self.username_attr in entry:
                    user["username"] = str(entry[self.username_attr])
                if self.email_attr in entry:
                    user["email"] = str(entry[self.email_attr])
                if self.first_name_attr in entry:
                    user["first_name"] = str(entry[self.first_name_attr])
                if self.last_name_attr in entry:
                    user["last_name"] = str(entry[self.last_name_attr])
                if "eduPersonAffiliation" in entry:
                    user["affiliation"] = str(entry["eduPersonAffiliation"])
                if "eduPersonEntitlement" in entry:
                    user["entitlement"] = str(entry["eduPersonEntitlement"])
                users.append(user)

            logger.info(f"Found {len(users)} users in LDAP")
            return users

        except Exception as e:
            logger.error(f"LDAP search failed: {e}")
            return []

    def disconnect(self) -> None:
        """Close LDAP connection"""
        if self.conn:
            self.conn.unbind()
            logger.info("Disconnected from LDAP")


class KeycloakAdminClient:
    """Keycloak admin API client for user management"""

    def __init__(self) -> None:
        self.url = os.getenv("KEYCLOAK_URL", "http://localhost:8080/auth")
        self.realm = os.getenv("KEYCLOAK_REALM", "opendesk")
        self.username = os.getenv("KEYCLOAK_ADMIN_USERNAME", "admin")
        self.password = os.getenv("KEYCLOAK_ADMIN_PASSWORD", "")
        self.admin = None

    def connect(self) -> bool:
        """Establish Keycloak admin connection"""
        try:
            self.admin = KeycloakAdmin(
                server_url=self.url,
                username=self.username,
                password=self.password,
                realm_name=self.realm,
                client_id="admin-cli",
            )
            logger.info(f"Connected to Keycloak: {self.url}/realms/{self.realm}")
            return True
        except Exception as e:
            logger.error(f"Keycloak connection failed: {e}")
            return False

    def user_exists(self, username: str) -> bool:
        """Check if user exists in Keycloak"""
        try:
            users = self.admin.get_users({"username": username, "exact": True})
            return len(users) > 0
        except Exception as e:
            logger.error(f"Failed to check user existence: {e}")
            return False

    def get_user(self, username: str) -> Optional[Dict]:
        """Get user by username"""
        try:
            users = self.admin.get_users({"username": username, "exact": True})
            if users:
                return users[0]
            return None
        except Exception as e:
            logger.error(f"Failed to get user: {e}")
            return None

    def create_user(self, user_data: Dict, dry_run: bool = False) -> bool:
        """Create user in Keycloak"""
        try:
            user_payload = {
                "username": user_data["username"],
                "email": user_data["email"],
                "firstName": user_data["first_name"],
                "lastName": user_data["last_name"],
                "enabled": True,
                "emailVerified": False,
            }

            if dry_run:
                logger.info(f"[DRY RUN] Would create user: {user_data['username']}")
                return True

            self.admin.create_user(user_payload)
            logger.info(f"Created user: {user_data['username']}")
            return True

        except Exception as e:
            logger.error(f"Failed to create user {user_data['username']}: {e}")
            return False

    def update_user(self, user_id: str, user_data: Dict, dry_run: bool = False) -> bool:
        """Update user in Keycloak"""
        try:
            user_payload = {
                "email": user_data["email"],
                "firstName": user_data["first_name"],
                "lastName": user_data["last_name"],
            }

            if dry_run:
                logger.info(f"[DRY RUN] Would update user: {user_data['username']}")
                return True

            self.admin.update_user(user_id, user_payload)
            logger.info(f"Updated user: {user_data['username']}")
            return True

        except Exception as e:
            logger.error(f"Failed to update user {user_data['username']}: {e}")
            return False

    def assign_role(self, username: str, role_name: str, dry_run: bool = False) -> bool:
        """Assign role to user"""
        try:
            user = self.get_user(username)
            if not user:
                logger.error(f"User {username} not found")
                return False

            # Get role
            roles = self.admin.get_realm_roles()
            role = next((r for r in roles if r["name"] == role_name), None)

            if not role:
                logger.error(f"Role {role_name} not found")
                return False

            if dry_run:
                logger.info(f"[DRY RUN] Would assign role {role_name} to {username}")
                return True

            self.admin.assign_realm_roles(user["id"], [role])
            logger.info(f"Assigned role {role_name} to {username}")
            return True

        except Exception as e:
            logger.error(f"Failed to assign role {role_name} to {username}: {e}")
            return False

    def assign_group(self, username: str, group_name: str, dry_run: bool = False) -> bool:
        """Assign group to user"""
        try:
            user = self.get_user(username)
            if not user:
                logger.error(f"User {username} not found")
                return False

            # Get group
            groups = self.admin.get_groups()
            group = next((g for g in groups if g["name"] == group_name), None)

            if not group:
                logger.warning(f"Group {group_name} not found, skipping")
                return True

            if dry_run:
                logger.info(f"[DRY RUN] Would assign group {group_name} to {username}")
                return True

            self.admin.group_user_add(user["id"], group["id"])
            logger.info(f"Assigned group {group_name} to {username}")
            return True

        except Exception as e:
            logger.error(f"Failed to assign group {group_name} to {username}: {e}")
            return False

    def disable_user(self, username: str, dry_run: bool = False) -> bool:
        """Disable user account"""
        try:
            user = self.get_user(username)
            if not user:
                logger.error(f"User {username} not found")
                return False

            if dry_run:
                logger.info(f"[DRY RUN] Would disable user: {username}")
                return True

            self.admin.update_user(user["id"], {"enabled": False})
            logger.info(f"Disabled user: {username}")
            return True

        except Exception as e:
            logger.error(f"Failed to disable user {username}: {e}")
            return False

    def delete_user(self, username: str, dry_run: bool = False) -> bool:
        """Delete user from Keycloak"""
        try:
            user = self.get_user(username)
            if not user:
                logger.error(f"User {username} not found")
                return False

            if dry_run:
                logger.info(f"[DRY RUN] Would delete user: {username}")
                return True

            self.admin.delete_user(user["id"])
            logger.warning(f"Deleted user: {username}")
            return True

        except Exception as e:
            logger.error(f"Failed to delete user {username}: {e}")
            return False


def load_role_mappings() -> Dict:
    """Load role mappings from config/roles.json"""
    try:
        import json

        with open("config/roles.json", "r") as f:
            config = json.load(f)
            return config.get("mappings", {})
    except Exception as e:
        logger.warning(f"Could not load role mappings: {e}")
        return {}


def map_affiliation_to_role(affiliation: str) -> str:
    """Map eduPersonAffiliation to Keycloak role"""
    role_mappings = load_role_mappings()
    affiliation_lower = affiliation.lower()
    return role_mappings.get(affiliation_lower, "student")


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync users from LDAP to Keycloak")
    parser.add_argument("--source", choices=["ldap"], default="ldap", help="Source system")
    parser.add_argument("--filter", help='LDAP filter string (e.g., "(eduPersonAffiliation=student)")')
    parser.add_argument("--auto-sync", action="store_true", help="Automatically sync all users")
    parser.add_argument("--auto-assign-roles", action="store_true", help="Assign roles based on affiliation")
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen without making changes")
    parser.add_argument("--disable-non-active", action="store_true", help="Disable users not found in LDAP")
    parser.add_argument("--grace-period-days", type=int, default=180, help="Grace period before archiving")

    args = parser.parse_args()

    dry_run = os.getenv("DRY_RUN", "false").lower() == "true" or args.dry_run

    logger.info(f"Starting user sync (dry_run={dry_run})")

    # Initialize clients
    ldap_client = LDAPClient()
    keycloak_client = KeycloakAdminClient()

    if not keycloak_client.connect():
        logger.error("Failed to connect to Keycloak, exiting")
        sys.exit(1)

    # Get users from LDAP
    ldap_users = ldap_client.search_users(args.filter)

    if not ldap_users:
        logger.warning("No users found in LDAP")
        sys.exit(0)

    # Statistics
    stats = {"synced": 0, "updated": 0, "skipped": 0, "failed": 0, "roles_assigned": 0}

    # Sync users
    for user in ldap_users:
        username = user.get("username")
        if not username:
            logger.warning("User without username, skipping")
            continue

        # Check if user exists
        if keycloak_client.user_exists(username):
            # Update existing user
            if keycloak_client.update_user(username, user, dry_run):
                stats["updated"] += 1
            else:
                stats["failed"] += 1
        else:
            # Create new user
            if keycloak_client.create_user(user, dry_run):
                stats["synced"] += 1
            else:
                stats["failed"] += 1

        # Assign roles if enabled
        if args.auto_assign_roles and "affiliation" in user:
            role = map_affiliation_to_role(user["affiliation"])
            if keycloak_client.assign_role(username, role, dry_run):
                stats["roles_assigned"] += 1

    # Disable non-active users if requested
    if args.disable_non_active:
        logger.info("Disabling users not found in LDAP")
        keycloak_users = keycloak_client.admin.get_users({"enabled": True})
        ldap_usernames = {u["username"] for u in ldap_users}

        for kc_user in keycloak_users:
            if kc_user["username"] not in ldap_usernames:
                if keycloak_client.disable_user(kc_user["username"], dry_run):
                    logger.info(f"Disabled non-active user: {kc_user['username']}")

    # Print statistics
    logger.info("Sync complete:")
    logger.info(f"  Synced: {stats['synced']}")
    logger.info(f"  Updated: {stats['updated']}")
    logger.info(f"  Roles assigned: {stats['roles_assigned']}")
    logger.info(f"  Failed: {stats['failed']}")

    ldap_client.disconnect()


if __name__ == "__main__":
    main()
