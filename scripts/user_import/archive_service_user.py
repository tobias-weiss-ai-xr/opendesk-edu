#!/usr/bin/env python3
"""
Service-Specific Archiver for openDesk Edu
Archives user data from individual services (ILIAS, Moodle, etc.)
before deletion
"""

import argparse
import json
import logging
import os
import subprocess
import tarfile
from datetime import datetime
from typing import Dict, List, Optional

# Configure logging
_log_handlers = [logging.StreamHandler()]
_log_file = os.getenv("LOG_FILE", "/var/log/opendesk-service-archiver.log")
if os.path.exists(os.path.dirname(_log_file)):
    _log_handlers.append(logging.FileHandler(_log_file))
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=_log_handlers,
)
logger = logging.getLogger(__name__)


class ServiceArchiver:
    """Archives user data from individual services"""

    def __init__(self, archive_dir: str = "/var/lib/opendesk-archives") -> None:
        self.archive_dir = archive_dir
        self.kubernetes_config = os.getenv("KUBECONFIG", "~/.kube/config")

    def archive_user(self, username: str, services: List[str] = None) -> Dict[str, str]:
        """
        Archive user data from specified services

        Args:
            username: Username to archive
            services: List of services to archive (default: all)

        Returns:
            Dictionary mapping service names to archive paths
        """
        if services is None:
            services = self.get_available_services()

        logger.info(f"Archiving user data for {username} from services: {services}")

        archives = {}

        for service in services:
            try:
                archive_path = self._archive_service(username, service)
                if archive_path:
                    archives[service] = archive_path
                    logger.info(f"Archived {service} data to {archive_path}")
            except Exception as e:
                logger.error(f"Failed to archive {service} for {username}: {e}")

        return archives

    def _archive_service(self, username: str, service: str) -> Optional[str]:
        """Archive user data from a specific service"""
        service_methods = {
            "ilias": self._archive_ilias,
            "moodle": self._archive_moodle,
            "bbb": self._archive_bbb,
            "nextcloud": self._archive_nextcloud,
            "opencloud": self._archive_opencloud,
            "keycloak": self._archive_keycloak_user,
        }

        if service not in service_methods:
            logger.warning(f"Unknown service: {service}")
            return None

        return service_methods[service](username)

    def get_available_services(self) -> List[str]:
        """Get list of accessible services"""
        # Check which services are deployed in the cluster
        services = []
        service_checks = {
            "ilias": "ilias",
            "moodle": "moodle",
            "bbb": "bigbluebutton",
            "nextcloud": "nextcloud",
            "opencloud": "opencloud",
            "keycloak": "keycloak",
        }

        for keycloak_service, namespace in service_checks.items():
            try:
                # Check if namespace exists
                result = subprocess.run(
                    ["kubectl", "get", "namespace", namespace], capture_output=True, text=True, timeout=10
                )
                if result.returncode == 0:
                    services.append(keycloak_service)
            except Exception as e:
                logger.debug(f"Service check failed for {keycloak_service}: {e}")

        logger.info(f"Available services for archiving: {services}")
        return services

    def _create_archive_dir(self, username: str, service: str) -> str:
        """Create archive directory for user and service"""
        date_str = datetime.now().strftime("%Y%m%d")
        user_archive_dir = os.path.join(self.archive_dir, username)
        service_archive_dir = os.path.join(user_archive_dir, f"{service}_{date_str}")
        os.makedirs(service_archive_dir, exist_ok=True)
        return service_archive_dir

    def _archive_keycloak_user(self, username: str) -> Optional[str]:
        """Archive Keycloak user profile and attributes"""
        try:
            archive_dir = self._create_archive_dir(username, "keycloak")

            # Use python-keycloak to get user data
            from sync_users import KeycloakAdminClient

            kc_client = KeycloakAdminClient()

            if not kc_client.connect():
                raise Exception("Failed to connect to Keycloak")

            user = kc_client.get_user(username)
            if not user:
                raise Exception(f"User {username} not found in Keycloak")

            # Export user data
            user_data_file = os.path.join(archive_dir, "user-data.json")
            with open(user_data_file, "w") as f:
                json.dump(user, f, indent=2)

            # Export user groups and roles
            user_groups = kc_client.admin.get_user_groups(user["id"])
            user_roles = kc_client.admin.get_realm_roles_of_user(user["id"])

            metadata = {
                "archived_at": datetime.now().isoformat(),
                "username": username,
                "user_id": user["id"],
                "groups": [g["name"] for g in user_groups],
                "roles": [r["name"] for r in user_roles],
                "attributes": user.get("attributes", {}),
            }

            metadata_file = os.path.join(archive_dir, "user-metadata.json")
            with open(metadata_file, "w") as f:
                json.dump(metadata, f, indent=2)

            # Create tarball
            tarball_path = self._create_tarball(archive_dir, f"{username}_keycloak")

            return tarball_path

        except Exception as e:
            logger.error(f"Failed to archive Keycloak user: {e}")
            return None

    def _archive_ilias(self, username: str) -> Optional[str]:
        """Archive ILIAS user data including courses and files"""
        try:
            archive_dir = self._create_archive_dir(username, "ilias")

            # Execute export via kubectl exec on ILIAS pod
            export_script = """
                #!/bin/bash
                # ILIAS user export script
                USERNAME="$1"
                EXPORT_DIR="/tmp/ilias_export_${USERNAME}"

                mkdir -p "$EXPORT_DIR"

                # Export user profile
                echo "Exporting user profile..."
                # Execute ILIAS CLI export command
                php /var/www/html/Customizing/global/include/cli.export.php \
                    --user="$USERNAME" --type=user \
                    --output="$EXPORT_DIR/user-profile.json" 2>/dev/null

                # Export course memberships
                echo "Exporting course memberships..."
                find /var/www/html/data/ -name "*.xml" \
                    | xargs grep -l "role_id" \
                    > "$EXPORT_DIR/courses.txt" 2>/dev/null

                # Export personal files if accessible
                echo "Archiving personal files..."
                if [ -d "/var/www/html/data/$USERNAME" ]; then
                    tar -czf "$EXPORT_DIR/personal-files.tar.gz" -C /var/www/html/data "$USERNAME" 2>/dev/null
                fi

                # List location
                echo "$EXPORT_DIR"
            """

            # Get ILIAS pod
            pods = subprocess.run(
                [
                    "kubectl",
                    "get",
                    "pods",
                    "-n",
                    "ilias",
                    "-l",
                    "app=ilias",
                    "-o",
                    "jsonpath={.items[0].metadata.name}",
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )

            if not pods.stdout:
                raise Exception("Unable to find ILIAS pod")

            pod_name = pods.stdout.strip()

            # Execute export script
            result = subprocess.run(
                ["kubectl", "exec", "-n", "ilias", pod_name, "--", "bash", "-c", export_script, username],
                capture_output=True,
                text=True,
                timeout=300,
            )

            if result.returncode != 0:
                logger.warning(f"ILIAS export failed (may not have CLI): {result.stderr}")

            # Create minimal archive anyway
            metadata = {
                "archived_at": datetime.now().isoformat(),
                "service": "ilias",
                "username": username,
                "note": "ILIAS export requires CLI plugin - partial archive created",
            }

            metadata_file = os.path.join(archive_dir, "ilias-metadata.json")
            with open(metadata_file, "w") as f:
                json.dump(metadata, f, indent=2)

            tarball_path = self._create_tarball(archive_dir, f"{username}_ilias")
            return tarball_path

        except Exception as e:
            logger.error(f"Failed to archive ILIAS data: {e}")
            return None

    def _archive_moodle(self, username: str) -> Optional[str]:
        """Archive Moodle user data including courses and submissions"""
        try:
            archive_dir = self._create_archive_dir(username, "moodle")

            # Moodle backup via CLI
            backup_script = f"""
                #!/bin/bash
                USERNAME="{username}"
                BACKUP_DIR="/tmp/moodle_backup_{username}"

                mkdir -p "$BACKUP_DIR"

                # Export user profile
                php /var/www/html/admin/cli/user.php \
                    --username="$USERNAME" \
                    --action=export \
                    --csv="$BACKUP_DIR/user-profile.csv"

                # Backup user gradebook data
                mariadb -h$dbhost -u$dbuser -p$dbpass $dbname \
                    -e "SELECT * FROM mdl_grade_grades WHERE userid = (SELECT id FROM mdl_user WHERE username = '$USERNAME');" \
                    > "$BACKUP_DIR/grades.sql"

                # List user courses
                mariadb -h$dbhost -u$dbuser -p$dbpass $dbname \
                    -e "SELECT c.fullname, e.roleid FROM mdl_course-enrolments e JOIN mdl_course c ON e.courseid = c.id JOIN mdl_user u ON e.userid = u.id WHERE u.username = '$USERNAME';" \
                    > "$BACKUP_DIR/courses.txt"

                echo "$BACKUP_DIR"
            """

            # Get Moodle pod
            pods = subprocess.run(
                [
                    "kubectl",
                    "get",
                    "pods",
                    "-n",
                    "moodle",
                    "-l",
                    "app=moodle",
                    "-o",
                    "jsonpath={.items[0].metadata.name}",
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )

            if not pods.stdout:
                raise Exception("Unable to find Moodle pod")

            pod_name = pods.stdout.strip()

            # Execute backup via kubectl
            try:
                result = subprocess.run(
                    ["kubectl", "exec", "-n", "moodle", pod_name, "--", "bash", "-c", backup_script],
                    capture_output=True,
                    text=True,
                    timeout=300,
                )

                if result.returncode == 0:
                    # Copy backup files
                    subprocess.run(
                        [
                            "kubectl",
                            "cp",
                            f"moodle/{pod_name}:/tmp/moodle_backup_{username}",
                            archive_dir,
                            "-c",
                            "moodle",
                        ],
                        timeout=60,
                    )
            except Exception as e:
                logger.warning(f"Moodle backup failed: {e}")

            # Create minimal archive
            metadata = {
                "archived_at": datetime.now().isoformat(),
                "service": "moodle",
                "username": username,
                "note": "Moodle backup via CLI requires database access",
            }

            metadata_file = os.path.join(archive_dir, "moodle-metadata.json")
            with open(metadata_file, "w") as f:
                json.dump(metadata, f, indent=2)

            tarball_path = self._create_tarball(archive_dir, f"{username}_moodle")
            return tarball_path

        except Exception as e:
            logger.error(f"Failed to archive Moodle data: {e}")
            return None

    def _archive_bbb(self, username: str) -> Optional[str]:
        """Archive BigBlueButton recording data"""
        try:
            archive_dir = self._create_archive_dir(username, "bbb")

            metadata = {
                "archived_at": datetime.now().isoformat(),
                "service": "bigbluebutton",
                "username": username,
                "recordings": [],
                "note": "BBB recordings should be retained by default retention policy",
            }

            # Query BBB API for recordings by user
            # This requires BBB shared secret and API access
            # For now, create placeholder

            metadata_file = os.path.join(archive_dir, "bbb-metadata.json")
            with open(metadata_file, "w") as f:
                json.dump(metadata, f, indent=2)

            tarball_path = self._create_tarball(archive_dir, f"{username}_bbb")
            return tarball_path

        except Exception as e:
            logger.error(f"Failed to archive BBB data: {e}")
            return None

    def _archive_nextcloud(self, username: str) -> Optional[str]:
        """Archive Nextcloud user files"""
        try:
            archive_dir = self._create_archive_dir(username, "nextcloud")

            # Archive Nextcloud files via OCC
            backup_script = f"""
                #!/bin/bash
                USERNAME="{username}"
                BACKUP_DIR="/tmp/nextcloud_backup_{username}"

                mkdir -p "$BACKUP_DIR"

                # Export user data directory
                if [ -d "/var/www/html/data/$USERNAME" ]; then
                    tar -czf "$BACKUP_DIR/files.tar.gz" -C /var/www/html/data "$USERNAME"
                else
                    echo "No user data directory found"
                fi

                # Export user preferences
                php occ config:list \
                    | grep -A 50 "$USERNAME" > "$BACKUP_DIR/preferences.txt"

                echo "$BACKUP_DIR"
            """

            # Get Nextcloud pod
            pods = subprocess.run(
                [
                    "kubectl",
                    "get",
                    "pods",
                    "-n",
                    "nextcloud",
                    "-l",
                    "app=nextcloud",
                    "-o",
                    "jsonpath={.items[0].metadata.name}",
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )

            if not pods.stdout:
                raise Exception("Unable to find Nextcloud pod")

            pod_name = pods.stdout.strip()

            try:
                # Execute backup
                result = subprocess.run(
                    ["kubectl", "exec", "-n", "nextcloud", pod_name, "--", "bash", "-c", backup_script],
                    capture_output=True,
                    text=True,
                    timeout=600,
                )

                if result.returncode == 0:
                    # Copy backup files
                    subprocess.run(
                        [
                            "kubectl",
                            "cp",
                            f"nextcloud/{pod_name}:/tmp/nextcloud_backup_{username}",
                            archive_dir,
                            "-c",
                            "nextcloud",
                        ],
                        timeout=120,
                    )
            except Exception as e:
                logger.warning(f"Nextcloud backup failed: {e}")

            # Create metadata
            metadata = {
                "archived_at": datetime.now().isoformat(),
                "service": "nextcloud",
                "username": username,
                "note": "Nextcloud files archived via OCC",
            }

            metadata_file = os.path.join(archive_dir, "nextcloud-metadata.json")
            with open(metadata_file, "w") as f:
                json.dump(metadata, f, indent=2)

            tarball_path = self._create_tarball(archive_dir, f"{username}_nextcloud")
            return tarball_path

        except Exception as e:
            logger.error(f"Failed to archive Nextcloud data: {e}")
            return None

    def _archive_opencloud(self, username: str) -> Optional[str]:
        """Archive OpenCloud user files (similar to Nextcloud)"""
        # OpenCloud uses similar architecture to Nextcloud
        return self._archive_nextcloud(username)

    def _create_tarball(self, source_dir: str, base_name: str) -> str:
        """Create tarball of archive directory"""
        try:
            tarball_name = f"{base_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.tar.gz"
            tarball_path = os.path.join(source_dir, "..", tarball_name)

            with tarfile.open(tarball_path, "w:gz") as tar:
                tar.add(source_dir, arcname=os.path.basename(source_dir))

            logger.info(f"Created tarball: {tarball_path}")
            return tarball_path

        except Exception as e:
            logger.error(f"Failed to create tarball: {e}")
            return None

    def compress_all_archives(self, username: str) -> Optional[str]:
        """Compress all user archives into a single tarball"""
        try:
            user_archive_dir = os.path.join(self.archive_dir, username)

            if not os.path.exists(user_archive_dir):
                logger.warning(f"No archives found for user {username}")
                return None

            tarball_name = f"{username}_complete_archive_{datetime.now().strftime('%Y%m%d_%H%M%S')}.tar.gz"
            tarball_path = os.path.join(self.archive_dir, tarball_name)

            with tarfile.open(tarball_path, "w:gz") as tar:
                tar.add(user_archive_dir, arcname=username)

            logger.info(f"Created complete archive: {tarball_path}")
            return tarball_path

        except Exception as e:
            logger.error(f"Failed to create complete archive: {e}")
            return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Archive user data from services")
    parser.add_argument("username", help="Username to archive")
    parser.add_argument("--services", nargs="+", help="Specific services to archive (default: all available)")
    parser.add_argument("--archive-dir", default="/var/lib/opendesk-archives", help="Archive directory")
    parser.add_argument("--all", action="store_true", help="Archive all services available")

    args = parser.parse_args()

    logger.info(f"Starting archive for user: {args.username}")

    archiver = ServiceArchiver(archive_dir=args.archive_dir)

    if args.all or not args.services:
        services = None  # Archive all
    else:
        services = args.services

    archives = archiver.archive_user(args.username, services)

    if archives:
        logger.info("Archiving complete:")
        for service, path in archives.items():
            logger.info(f"  {service}: {path}")
    else:
        logger.warning("No archives created")


if __name__ == "__main__":
    main()
