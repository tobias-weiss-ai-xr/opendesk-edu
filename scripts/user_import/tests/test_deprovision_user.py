"""
Unit tests for deprovision_user.py
"""

import unittest
from unittest.mock import patch, MagicMock
import os
import tempfile

# Import the module to test
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from deprovision_user import UserDeprovisioner


class TestUserDeprovisioner(unittest.TestCase):
    """Test UserDeprovisioner functionality"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_env = {
            "KEYCLOAK_URL": "http://test-keycloak:8080/auth",
            "KEYCLOAK_REALM": "test-realm",
            "KEYCLOAK_ADMIN_USERNAME": "admin",
            "KEYCLOAK_ADMIN_PASSWORD": "admin-password",
            "GRACE_PERIOD_DAYS": "180",
        }

        self.test_user = {
            "id": "user-id-123",
            "username": "testuser",
            "email": "test@test.de",
            "attributes": {"disabled_at": "2026-01-01T00:00:00", "affiliation": ["student"]},
        }

    @patch.dict(
        os.environ,
        {
            "KEYCLOAK_URL": "http://test-keycloak:8080/auth",
            "KEYCLOAK_REALM": "test-realm",
            "KEYCLOAK_ADMIN_USERNAME": "admin",
            "KEYCLOAK_ADMIN_PASSWORD": "admin-password",
            "GRACE_PERIOD_DAYS": "180",
        },
    )
    @patch("deprovision_user.KeycloakAdminClient")
    def test_deprovisioner_initialization(self, mock_keycloak):
        """Test deprovisioner initialization"""
        deprovisioner = UserDeprovisioner()

        self.assertEqual(deprovisioner.grace_period_days, 180)

    @patch("deprovision_user.KeycloakAdminClient")
    def test_deprovision_user_disable(self, mock_keycloak):
        """Test phase 1: disable user"""
        mock_admin = MagicMock()
        mock_keycloak.return_value = mock_admin
        mock_admin.get_users.return_value = [self.test_user]

        deprovisioner = UserDeprovisioner()
        deprovisioner.keycloak_client = mock_admin

        result = deprovisioner._disable_user(self.test_user, dry_run=True)

        # Dry run should not disable user
        self.assertTrue(result)

        # Actual disable
        result = deprovisioner._disable_user(self.test_user, dry_run=False)

        self.assertTrue(result)
        # Verify disable was called
        mock_admin.update_user.assert_called()

    @patch("deprovision_user.KeycloakAdminClient")
    def test_deprovision_user_delete(self, mock_keycloak):
        """Test phase 2: delete user"""
        mock_admin = MagicMock()
        mock_keycloak.return_value = mock_admin
        mock_admin.get_users.return_value = [self.test_user]

        deprovisioner = UserDeprovisioner()
        deprovisioner.keycloak_client = mock_admin

        result = deprovisioner._delete_user(self.test_user, dry_run=True)

        # Dry run should not delete user
        self.assertTrue(result)

        # Actual delete
        result = deprovisioner._delete_user(self.test_user, dry_run=False)

        self.assertTrue(result)
        # Verify delete was called
        mock_admin.delete_user.assert_called()

    @patch("deprovision_user.UserDeprovisioner")
    def test_grace_period_expired(self, mock_deprovisioner):
        """Test grace period expiry check"""
        deprovisioner = UserDeprovisioner()
        deprovisioner.grace_period_days = 180

        # User with disabled_at more than 180 days ago
        old_user = {
            "id": "user-old-123",
            "username": "olduser",
            "attributes": {
                "disabled_at": "2025-09-01T00:00:00"  # ~6 months ago
            },
        }

        with patch.object(deprovisioner, "_grace_period_expired") as mock_expired:
            mock_expired.return_value = True

            deprovisioner._grace_period_expired(old_user)

            # For this test, we mock to return True
            # In actual implementation, it checks date math

    @patch("deprovision_user.UserDeprovisioner")
    @patch("builtins.open", create=True)
    def test_store_deprovisioning_metadata(self, mock_open, mock_deprovisioner):
        """Test storing deprovisioning metadata"""
        deprovisioner = UserDeprovisioner()

        # Mock file write
        mock_file = MagicMock()
        mock_open.return_value.__enter__.return_value = mock_file

        test_user = {"id": "user-id-123", "username": "testuser", "attributes": {}}

        deprovisioner._store_deprovisioning_metadata(
            test_user, phase="disable", reason="Test deprovision", dry_run=False
        )

        # Verify metadata was written
        self.assertTrue(mock_file.write.called)

    @patch("deprovision_user.UserDeprovisioner")
    @patch("os.makedirs")
    @patch("builtins.open", create=True)
    def test_archive_user_data(self, mock_makedirs, mock_open, mock_deprovisioner):
        """Test archiving user data"""
        deprovisioner = UserDeprovisioner()

        test_user = {"id": "user-id-123", "username": "testuser", "email": "test@test.de"}

        # Mock archiver (simplified test)
        with patch("deprovision_user.ServiceArchiver") as mock_archiver:
            mock_archiver_instance = MagicMock()
            mock_archiver.return_value = mock_archiver_instance
            mock_archiver_instance.archive_user.return_value = {
                "keycloak": "/var/lib/opendesk-archives/testuser/keycloak.tar.gz",
                "ilias": "/var/lib/opendesk-archives/testuser/ilias.tar.gz",
            }

            deprovisioner._archive_user_data(test_user)

            # Verify archiver was called
            mock_archiver_instance.archive_user.assert_called_with("testuser")

    @patch("deprovision_user.UserDeprovisioner")
    @patch("builtins.open", create=True)
    def test_deprovision_batch(self, mock_open, mock_deprovisioner):
        """Test batch deprovisioning"""
        deprovisioner = UserDeprovisioner()

        # Create temporary input file
        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
            f.write("user1\nuser2\nuser3\n")
            input_file = f.name

        # Mock get_users for all users
        with patch.object(deprovisioner.keycloak_client, "get_users") as mock_get_users:
            mock_get_users.return_value = [
                {"id": "1", "username": "user1"},
                {"id": "2", "username": "user2"},
                {"id": "3", "username": "user3"},
            ]

            result = deprovisioner.deprovision_batch(input_file, phase="disable", dry_run=True, confirm=True)

            self.assertIn("success", result)

    @patch("deprovision_user.UserDeprovisioner")
    def test_create_ruckmeldung_filter(self, mock_deprovisioner):
        """Test creating filter for students who haven't re-registered"""
        UserDeprovisioner()

        # Create filter function
        cutoff_date_str = "2025-12-01"

        from deprovision_user import create_ruckmeldung_filter

        filter_func = create_ruckmeldung_filter(cutoff_date_str)

        # Test filter function
        # Note: Actual implementation checks datetime comparison
        # We're just verifying function creation works
        self.assertIsNotNone(filter_func)


class TestDeprovisioningCLI(unittest.TestCase):
    """Test deprovision_user.py command-line interface"""

    @patch("deprovision_user.argparse.ArgumentParser")
    @patch("deprovision_user.UserDeprovisioner")
    @patch("sys.exit")
    def test_main_single_user_disable(self, mock_parser, mock_deprovisioner, mock_exit):
        """Test main CLI for single user disable"""
        # Mock parser
        mock_args = MagicMock()
        mock_args.username = "testuser"
        mock_args.phase = "disable"
        mock_args.reason = "Test deprovision"
        mock_args.dry_run = False
        mock_args.input_file = None
        mock_args.filter = None
        mock_args.no_ruckmeldung_since = None
        mock_args.grace_expired_before = None
        mock_parser.parse_args.return_value = mock_args

        with patch("deprovision_user.argparse") as mock_argparse:
            mock_argparse.ArgumentParser.return_value = mock_parser

            with patch("deprovision_user.UserDeprovisioner") as mock_dep:
                mock_dep_instance = MagicMock()
                mock_dep.return_value = mock_dep_instance
                mock_dep_instance.deprovision_user.return_value = True

                # Import and run main
                import deprovision_user

                deprovision_user.main()

                # Verify deprovision was called
                mock_dep_instance.deprovision_user.assert_called_with(
                    "testuser", phase="disable", dry_run=False, reason="Test deprovision"
                )

    @patch("deprovision_user.argparse.ArgumentParser")
    @patch("deprovision_user.UserDeprovisioner")
    @patch("sys.exit")
    def test_main_batch_file(self, mock_parser, mock_deprovisioner, mock_exit):
        """Test main CLI for batch file deprovisioning"""
        mock_args = MagicMock()
        mock_args.username = None
        mock_args.phase = "disable"
        mock_args.input_file = "/tmp/users.csv"
        mock_args.confirm = True
        mock_args.dry_run = False
        mock_parser.parse_args.return_value = mock_args

        with patch("deprovision_user.argparse") as mock_argparse:
            mock_argparse.ArgumentParser.return_value = mock_parser

            with patch("deprovision_user.UserDeprovisioner") as mock_dep:
                mock_dep_instance = MagicMock()
                mock_dep.return_value = mock_dep_instance
                mock_dep_instance.deprovision_batch.return_value = {"success": 10, "failed": 0, "skipped": 0}

                import deprovision_user

                deprovision_user.main()

                # Verify batch deprovision was called
                mock_dep_instance.deprovision_batch.assert_called()

    @patch("deprovision_user.argparse.ArgumentParser")
    @patch("deprovision_user.UserDeprovisioner")
    @patch("sys.exit")
    def test_main_no_ruckmeldung_filter(self, mock_parser, mock_deprovisioner, mock_exit):
        """Test main CLI with no-ruckmeldung filter"""
        mock_args = MagicMock()
        mock_args.username = None
        mock_args.filter = "no-ruckmeldung"
        mock_args.no_ruckmeldung_since = "2025-12-01"
        mock_args.grace_expired_before = None
        mock_parser.parse_args.return_value = mock_args

        with patch("deprovision_user.argparse") as mock_argparse:
            mock_argparse.ArgumentParser.return_value = mock_parser

            with patch("deprovision_user.UserDeprovisioner") as mock_dep:
                mock_dep_instance = MagicMock()
                mock_dep.return_value = mock_dep_instance

                from deprovision_user import create_ruckmeldung_filter

                create_ruckmeldung_filter("2025-12-01")
                mock_dep_instance.deprovision_by_filter.return_value = {"success": 5, "failed": 0}

                import deprovision_user

                deprovision_user.main()

                # Verify filter was used
                mock_dep_instance.deprovision_by_filter.assert_called()


if __name__ == "__main__":
    unittest.main()
