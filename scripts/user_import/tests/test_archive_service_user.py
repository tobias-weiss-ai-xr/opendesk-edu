"""
Unit tests for archive_service_user.py
"""

import unittest
from unittest.mock import patch, MagicMock
import os
import tempfile
import json

# Import the module to test
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from archive_service_user import ServiceArchiver


class TestServiceArchiver(unittest.TestCase):
    """Test ServiceArchiver functionality"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_env = {
            "KUBECONFIG": "/tmp/test-kubeconfig",
        }

        self.test_username = "testuser"
        self.test_services = ["keycloak", "ilias", "moodle", "bbb", "nextcloud"]

    @patch.dict(os.environ, {"KUBECONFIG": "/tmp/test-kubeconfig"})
    def test_archiver_initialization(self):
        """Test archiver initialization"""
        archiver = ServiceArchiver(archive_dir="/tmp/test-archives")

        self.assertEqual(archiver.archive_dir, "/tmp/test-archives")
        self.assertEqual(archiver.kubernetes_config, "/tmp/test-kubeconfig")

    @patch("archive_service_user.subprocess.run")
    def test_archive_keycloak_user(self, mock_run):
        """Test archiving Keycloak user"""
        archiver = ServiceArchiver()

        # Mock kubectl get pods
        mock_run.return_value = MagicMock(stdout="keycloak-0", returncode=0)

        # Mock KeycloakAdminClient
        with patch("archive_service_user.KeycloakAdminClient") as mock_keycloak:
            mock_admin = MagicMock()
            mock_keycloak.return_value = mock_admin
            mock_admin.connect.return_value = True
            mock_admin.get_user.return_value = {
                "id": "123",
                "username": self.test_username,
                "email": "test@test.de",
                "firstName": "Test",
                "lastName": "User",
            }
            mock_admin.get_user_groups.return_value = []
            mock_admin.get_realm_roles_of_user.return_value = []

            # Mock subprocess for tarball
            with patch("archive_service_user.tarfile") as mock_tarfile:
                mock_tar = MagicMock()
                mock_tarfile.open.return_value = mock_tar

                result = archiver._archive_keycloak(self.test_username)

                # Verify archiver ran
                self.assertIsNotNone(result)

    @patch("archive_service_user.subprocess.run")
    def test_archive_ilias(self, mock_run):
        """Test archiving ILIAS user data"""
        archiver = ServiceArchiver()

        # Mock kubectl get pods
        mock_run.return_value = MagicMock(stdout="ilias-0", returncode=0)

        with patch("archive_service_user.tarfile") as mock_tarfile:
            mock_tar = MagicMock()
            mock_tarfile.open.return_value = mock_tar

            result = archiver._archive_ilias(self.test_username)

            # Verify archiver ran (returns path to tarball)
            self.assertIsNotNone(result)

    @patch("archive_service_user.subprocess.run")
    def test_archive_moodle(self, mock_run):
        """Test archiving Moodle user data"""
        archiver = ServiceArchiver()

        # Mock kubectl get pods
        mock_run.return_value = MagicMock(stdout="moodle-0", returncode=0)

        with patch("archive_service_user.tarfile") as mock_tarfile:
            mock_tar = MagicMock()
            mock_tarfile.open.return_value = mock_tar

            result = archiver._archive_moodle(self.test_username)

            self.assertIsNotNone(result)

    @patch("archive_service_user.subprocess.run")
    def test_archive_bbb(self, mock_run):
        """Test archiving BBB user data"""
        archiver = ServiceArchiver()

        # Mock kubectl get pods
        mock_run.return_value = MagicMock(stdout="bbb-0", returncode=0)

        with patch("archive_service_user.tarfile") as mock_tarfile:
            mock_tar = MagicMock()
            mock_tarfile.open.return_value = mock_tar

            result = archiver._archive_bbb(self.test_username)

            self.assertIsNotNone(result)

    @patch("archive_service_user.subprocess.run")
    def test_archive_nextcloud(self, mock_run):
        """Test archiving Nextcloud user data"""
        archiver = ServiceArchiver()

        # Mock kubectl get pods
        mock_run.return_value = MagicMock(stdout="nextcloud-0", returncode=0)

        with patch("archive_service_user.tarfile") as mock_tarfile:
            mock_tar = MagicMock()
            mock_tarfile.open.return_value = mock_tar

            result = archiver._archive_nextcloud(self.test_username)

            self.assertIsNotNone(result)

    @patch("archive_service_user.subprocess.run")
    def test_archive_user_all_services(self, mock_run):
        """Test archiving user data from all services"""
        archiver = ServiceArchiver()

        # Mock kubectl pod lookups
        mock_run.side_effect = [
            MagicMock(stdout="keycloak-0", returncode=0),
            MagicMock(stdout="ilias-0", returncode=0),
            MagicMock(stdout="moodle-0", returncode=0),
            MagicMock(stdout="bbb-0", returncode=0),
            MagicMock(stdout="nextcloud-0", returncode=0),
        ]

        with patch("archive_service_user.tarfile") as mock_tarfile:
            mock_tar = MagicMock()
            mock_tarfile.open.return_value = mock_tar

            # Mock individual archive methods
            with patch.object(archiver, "_archive_keycloak") as mock_keycloak:
                mock_keycloak.return_value = "/tmp/test-archives/testuser/keycloak.tar.gz"

                with patch.object(archiver, "_archive_ilias") as mock_ilias:
                    mock_ilias.return_value = "/tmp/test-archives/testuser/ilias.tar.gz"

                    with patch.object(archiver, "_archive_moodle") as mock_moodle:
                        mock_moodle.return_value = "/tmp/test-archives/testuser/moodle.tar.gz"

                        with patch.object(archiver, "_archive_bbb") as mock_bbb:
                            mock_bbb.return_value = "/tmp/test-archives/testuser/bbb.tar.gz"

                            with patch.object(archiver, "_archive_nextcloud") as mock_nextcloud:
                                mock_nextcloud.return_value = "/tmp/test-archives/testuser/nextcloud.tar.gz"

                                archives = archiver.archive_user(self.test_username)

                                # Verify all archives were created
                                self.assertIn("keycloak", archives)
                                self.assertIn("ilias", archives)
                                self.assertIn("moodle", archives)
                                self.assertIn("bbb", archives)
                                self.assertIn("nextcloud", archives)

    @patch("archive_service_user.tarfile")
    def test_create_tarball(self, mock_tarfile):
        """Test creating tarball from archive directory"""
        archiver = ServiceArchiver()

        # Mock tarfile.open and tarfile.TarFile
        mock_tar = MagicMock()
        mock_tarfile.open.return_value = mock_tar

        source_dir = tempfile.mkdtemp()
        base_name = "test_user"

        # Create dummy file in source directory
        test_file = os.path.join(source_dir, "test.txt")
        with open(test_file, "w") as f:
            f.write("test content")

        result = archiver._create_tarball(source_dir, base_name)

        # Verify tarball was created
        self.assertIsNotNone(result)
        self.assertTrue(result.endswith(".tar.gz"))

        # Cleanup
        import shutil

        shutil.rmtree(source_dir)

    @patch("archive_service_user.subprocess.run")
    def test_compress_all_archives(self, mock_run):
        """Test compressing all user archives"""
        archiver = ServiceArchiver()

        # Create test archive structure
        with tempfile.TemporaryDirectory() as test_archives:
            user_dir = os.path.join(test_archives, self.test_username)
            os.makedirs(user_dir)

            # Create dummy archive directories
            for service in ["keycloak", "ilias"]:
                service_dir = os.path.join(user_dir, f"{service}_20260406")
                os.makedirs(service_dir)

                # Create dummy files
                with open(os.path.join(service_dir, "data.json"), "w") as f:
                    json.dump({"test": "data"}, f)

            with patch("archive_service_user.tarfile") as mock_tarfile:
                mock_tar = MagicMock()
                mock_tarfile.open.return_value = mock_tar

                result = archiver.compress_all_archives(self.test_username)

                # Verify complete archive was created
                self.assertIsNotNone(result)
                self.assertTrue("complete_archive" in result)


class TestServiceArchiverCLI(unittest.TestCase):
    """Test archive_service_user.py command-line interface"""

    @patch("archive_service_user.argparse.ArgumentParser")
    @patch("archive_service_user.ServiceArchiver")
    def test_main_archive_single_user(self, mock_parser, mock_archiver):
        """Test main CLI for archiving single user"""
        mock_args = MagicMock()
        mock_args.username = self.test_username
        mock_args.services = None
        mock_args.all = False
        mock_args.archive_dir = "/tmp/test-archives"
        mock_parser.parse_args.return_value = mock_args

        with patch("archive_service_user.argparse") as mock_argparse:
            mock_argparse.ArgumentParser.return_value = mock_parser

            with patch("archive_service_user.ServiceArchiver") as mock_archiver_cls:
                mock_archiver = MagicMock()
                mock_archiver_cls.return_value = mock_archiver
                mock_archiver.archive_user.return_value = {
                    "keycloak": "/tmp/test-archives/testuser/keycloak.tar.gz",
                    "ilias": "/tmp/test-archives/testuser/ilias.tar.gz",
                }

                # Import and run main
                import archive_service_user

                archive_service_user.main()

                # Verify archive_user was called
                mock_archiver.archive_user.assert_called_with(
                    self.test_username,
                    None,  # services=None means all
                )

    @patch("archive_service_user.argparse.ArgumentParser")
    @patch("archive_service_user.ServiceArchiver")
    def test_main_archive_specific_services(self, mock_parser, mock_archiver):
        """Test main CLI for archiving specific services"""
        mock_args = MagicMock()
        mock_args.username = self.test_username
        mock_args.services = ["keycloak", "ilias"]
        mock_args.all = False
        mock_args.archive_dir = "/tmp/test-archives"
        mock_parser.parse_args.return_value = mock_args

        with patch("archive_service_user.argparse") as mock_argparse:
            mock_argparse.ArgumentParser.return_value = mock_parser

            with patch("archive_service_user.ServiceArchiver") as mock_archiver_cls:
                mock_archiver = MagicMock()
                mock_archiver_cls.return_value = mock_archiver
                mock_archiver.archive_user.return_value = {
                    "keycloak": "/tmp/test-archives/testuser/keycloak.tar.gz",
                    "ilias": "/tmp/test-archives/testuser/ilias.tar.gz",
                }

                # Import and run main
                import archive_service_user

                archive_service_user.main()

                # Verify archive_user was called with specific services
                mock_archiver.archive_user.assert_called_with(self.test_username, ["keycloak", "ilias"])

    @patch("archive_service_user.argparse.ArgumentParser")
    @patch("archive_service_user.ServiceArchiver")
    def test_main_archive_all(self, mock_parser, mock_archiver):
        """Test main CLI for archiving all services"""
        mock_args = MagicMock()
        mock_args.username = self.test_username
        mock_args.services = None
        mock_args.all = True
        mock_args.archive_dir = "/tmp/test-archives"
        mock_parser.parse_args.return_value = mock_args

        with patch("archive_service_user.argparse") as mock_argparse:
            mock_argparse.ArgumentParser.return_value = mock_parser

            with patch("archive_service_user.ServiceArchiver") as mock_archiver_cls:
                mock_archiver = MagicMock()
                mock_archiver_cls.return_value = mock_archiver
                mock_archiver.archive_user.return_value = {
                    "keycloak": "/tmp/test-archives/testuser/keycloak.tar.gz",
                    "ilias": "/tmp/test-archives/testuser/ilias.tar.gz",
                    "moodle": "/tmp/test-archives/testuser/moodle.tar.gz",
                    "bbb": "/tmp/test-archives/testuser/bbb.tar.gz",
                    "nextcloud": "/tmp/test-archives/testuser/nextcloud.tar.gz",
                }

                # Import and run main
                import archive_service_user

                archive_service_user.main()

                # Verify archive_user was called with all services
                mock_archiver.archive_user.assert_called_with(
                    self.test_username,
                    None,  # all=True means all services
                )


if __name__ == "__main__":
    unittest.main()
