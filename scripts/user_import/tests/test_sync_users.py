"""
Unit tests for sync_users.py
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import os
import tempfile
import json

# Import the module to test
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from sync_users import LDAPClient, KeycloakAdminClient, load_role_mappings, map_affiliation_to_role


class TestLDAPClient(unittest.TestCase):
    """Test LDAPClient functionality"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_env = {
            "LDAP_SERVER": "ldap://test-server",
            "LDAP_BASE_DN": "dc=test,dc=de",
            "LDAP_BIND_DN": "cn=admin,dc=test,dc=de",
            "LDAP_BIND_PASSWORD": "test-password",
            "LDAP_USER_SEARCH_BASE": "ou=users,dc=test,dc=de",
            "LDAP_USER_OBJECT_CLASS": "inetOrgPerson",
            "LDAP_USERNAME_ATTR": "uid",
            "LDAP_EMAIL_ATTR": "mail",
            "LDAP_FIRST_NAME_ATTR": "givenName",
            "LDAP_LAST_NAME_ATTR": "sn",
        }

    @patch.dict(
        os.environ,
        {
            "LDAP_SERVER": "ldap://test-server",
            "LDAP_BASE_DN": "dc=test,dc=de",
            "LDAP_BIND_DN": "cn=admin,dc=test,dc=de",
            "LDAP_BIND_PASSWORD": "test-password",
            "LDAP_USER_SEARCH_BASE": "ou=users,dc=test,dc=de",
            "LDAP_USER_OBJECT_CLASS": "inetOrgPerson",
        },
    )
    def test_ldap_client_initialization(self):
        """Test LDAP client initialization with environment variables"""
        client = LDAPClient()

        self.assertEqual(client.server, "ldap://test-server")
        self.assertEqual(client.base_dn, "dc=test,dc=de")
        self.assertEqual(client.bind_dn, "cn=admin,dc=test,dc=de")

    @patch("ldap3.Connection")
    def test_ldap_connect_success(self, mock_connection):
        """Test successful LDAP connection"""
        mock_conn = MagicMock()
        mock_connection.return_value = mock_conn
        mock_conn.bind.return_value = True

        client = LDAPClient()
        result = client.connect()

        self.assertTrue(result)
        mock_conn.bind.assert_called_once()

    @patch("ldap3.Connection")
    def test_ldap_search_users(self, mock_connection):
        """Test LDAP user search"""
        # Mock LDAP entry
        mock_entry = MagicMock()
        mock_entry.__getitem__ = Mock(side_effect=lambda x: f"test_value_{x}")
        mock_entry.keys.return_value = ["uid", "mail", "givenName", "sn", "eduPersonAffiliation"]

        mock_conn = MagicMock()
        mock_conn.entries = [mock_entry]
        mock_conn.search.return_value = True

        client = LDAPClient()
        client.conn = mock_conn

        client.search_users()

        # Verify search was called
        mock_conn.search.assert_called_once()


class TestKeycloakAdminClient(unittest.TestCase):
    """Test KeycloakAdminClient functionality"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_env = {
            "KEYCLOAK_URL": "http://test-keycloak:8080/auth",
            "KEYCLOAK_REALM": "test-realm",
            "KEYCLOAK_ADMIN_USERNAME": "admin",
            "KEYCLOAK_ADMIN_PASSWORD": "admin-password",
        }

    @patch.dict(
        os.environ,
        {
            "KEYCLOAK_URL": "http://test-keycloak:8080/auth",
            "KEYCLOAK_REALM": "test-realm",
            "KEYCLOAK_ADMIN_USERNAME": "admin",
            "KEYCLOAK_ADMIN_PASSWORD": "admin-password",
        },
    )
    @patch("sync_users.KeycloakAdmin")
    def test_keycloak_client_initialization(self, mock_keycloak):
        """Test Keycloak client initialization"""
        client = KeycloakAdminClient()

        # Note: KeycloakAdmin is mocked, so we verify initialization
        self.assertIsNotNone(client)

    @patch("sync_users.KeycloakAdmin")
    def test_user_exists(self, mock_keycloak):
        """Test checking if user exists"""
        mock_admin = MagicMock()
        mock_keycloak.return_value = mock_admin
        mock_admin.get_users.return_value = [{"username": "testuser"}]

        client = KeycloakAdminClient()
        client.admin = mock_admin

        exists = client.user_exists("testuser")

        self.assertTrue(exists)
        mock_admin.get_users.assert_called_with({"username": "testuser", "exact": True})

    @patch("sync_users.KeycloakAdmin")
    def test_get_user(self, mock_keycloak):
        """Test getting user by username"""
        mock_admin = MagicMock()
        mock_keycloak.return_value = mock_admin
        test_user = {"id": "123", "username": "testuser", "email": "test@test.de"}
        mock_admin.get_users.return_value = [test_user]

        client = KeycloakAdminClient()
        client.admin = mock_admin

        user = client.get_user("testuser")

        self.assertEqual(user, test_user)

    @patch("sync_users.KeycloakAdmin")
    def test_create_user(self, mock_keycloak):
        """Test creating user"""
        mock_admin = MagicMock()
        mock_keycloak.return_value = mock_admin
        mock_admin.create_user.return_value = "user-id-123"

        client = KeycloakAdminClient()
        client.admin = mock_admin

        user_data = {"username": "testuser", "email": "test@test.de", "first_name": "Test", "last_name": "User"}

        result = client.create_user(user_data, dry_run=True)

        # Dry run should not create user
        self.assertTrue(result)
        mock_admin.create_user.assert_not_called()

        # Actual creation
        result = client.create_user(user_data, dry_run=False)

        self.assertTrue(result)
        mock_admin.create_user.assert_called_once()

    @patch("sync_users.KeycloakAdmin")
    def test_assign_role(self, mock_keycloak):
        """Test assigning role to user"""
        mock_admin = MagicMock()
        mock_keycloak.return_value = mock_admin
        test_role = {"name": "student", "id": "role-id-123"}
        mock_admin.get_realm_roles.return_value = [test_role]
        test_user = {"id": "user-id-456", "username": "testuser"}
        mock_admin.get_users.return_value = [test_user]

        client = KeycloakAdminClient()
        client.admin = mock_admin

        result = client.assign_role("testuser", "student", dry_run=True)

        # Dry run should not assign role
        self.assertTrue(result)
        mock_admin.assign_realm_roles.assert_not_called()

        # Actual assignment
        result = client.assign_role("testuser", "student", dry_run=False)

        self.assertTrue(result)


class TestRoleMapping(unittest.TestCase):
    """Test role mapping functionality"""

    def test_load_role_mappings(self):
        """Test loading role mappings from config file"""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump({"mappings": {"student": "student", "faculty": "faculty", "dozent": "lecturer"}}, f)

        # Mock file read
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = json.dumps(
                {"mappings": {"student": "student", "faculty": "faculty", "dozent": "lecturer"}}
            )

            mappings = load_role_mappings()

            self.assertEqual(mappings["student"], "student")
            self.assertEqual(mappings["faculty"], "faculty")
            self.assertEqual(mappings["dozent"], "lecturer")

    def test_map_affiliation_to_role(self):
        """Test mapping affiliation to role"""
        with patch("sync_users.load_role_mappings") as mock_load:
            mock_load.return_value = {
                "student": "student",
                "faculty": "faculty",
                "employee": "employee",
            }

            self.assertEqual(map_affiliation_to_role("student"), "student")
            self.assertEqual(map_affiliation_to_role("faculty"), "faculty")
            self.assertEqual(map_affiliation_to_role("employee"), "employee")

            # Test unknown affiliation defaults to 'student'
            self.assertEqual(map_affiliation_to_role("unknown"), "student")


if __name__ == "__main__":
    unittest.main()
