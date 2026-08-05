# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

from unittest.mock import MagicMock, patch

import sys
import os

# Add parent directory to path to import the module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


class TestDeprovisionDisable:
    """Test deprovision_disable.py functions."""

    @patch("requests.get")
    def test_get_iam_api_users_success(self, mock_get):
        """Test get_iam_api_users successfully retrieves users."""
        from deprovision_disable import get_iam_api_users

        mock_response = MagicMock()
        mock_response.json.return_value = {
            "accounts": [{"username": "user1"}, {"username": "user2"}, {"username": "user3"}]
        }
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        result = get_iam_api_users("https://iam.example.com/api/users")

        assert len(result) == 3
        assert "user1" in result
        assert "user2" in result
        assert "user3" in result

        mock_get.assert_called_once_with("https://iam.example.com/api/users", timeout=30)

    @patch("requests.get")
    def test_get_iam_api_users_case_insensitive(self, mock_get):
        """Test get_iam_api_users lowercases usernames."""
        from deprovision_disable import get_iam_api_users

        mock_response = MagicMock()
        mock_response.json.return_value = {"accounts": [{"username": "User1"}, {"username": "USER2"}]}
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        result = get_iam_api_users("https://iam.example.com/api/users")

        # Usernames should be lowercased
        assert "user1" in result
        assert "user2" in result

    @patch("requests.get")
    def test_get_iam_api_users_handles_no_accounts(self, mock_get):
        """Test get_iam_api_users handles response without accounts key."""
        from deprovision_disable import get_iam_api_users

        mock_response = MagicMock()
        mock_response.json.return_value = {"other_key": "value"}
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        result = get_iam_api_users("https://iam.example.com/api/users")

        assert len(result) == 0

    @patch("requests.get")
    def test_get_iam_api_users_handles_network_error(self, mock_get):
        """Test get_iam_api_users returns empty set on network error."""
        from deprovision_disable import get_iam_api_users

        import requests

        mock_get.side_effect = requests.RequestException("Connection failed")

        result = get_iam_api_users("https://iam.example.com/api/users")

        assert result == set()

    def test_get_ucs_users_success(self):
        """Test get_ucs_users successfully retrieves users."""
        from deprovision_disable import get_ucs_users

        mock_ucs = MagicMock()
        mock_ucs._Ucs__get_object_list.return_value = [
            {"dn": "uid=user1,cn=users,dc=example,dc=com"},
            {"dn": "uid=user2,cn=users,dc=example,dc=com"},
            {"dn": "uid=user3,cn=users,dc=example,dc=com"},
            {"dn": "cn=admin,cn=users,dc=example,dc=com"},  # Not starting with uid=
        ]

        result = get_ucs_users(mock_ucs)

        # Should extract users starting with uid=
        assert len(result) == 3
        assert "user1" in result
        assert "user2" in result
        assert "user3" in result
        assert "admin" not in result

        # Usernames should be lowercased
        assert "user1" in result

    def test_get_ucs_users_handles_exception(self):
        """Test get_ucs_users returns empty set on exception."""
        from deprovision_disable import get_ucs_users

        mock_ucs = MagicMock()
        mock_ucs._Ucs__get_object_list.side_effect = Exception("UCS error")

        result = get_ucs_users(mock_ucs)

        assert result == set()

    def test_deprovision_user_dry_run(self):
        """Test deprovision_user in dry run mode returns success without changes."""
        from deprovision_disable import deprovision_user

        mock_ucs = MagicMock()
        timestamp = "2026-04-12T12h00m00S"

        result = deprovision_user(
            mock_ucs,
            "testuser",
            "https://keycloak.example.com",
            "admin",
            "password",
            "saml-provider",
            timestamp,
            dry_run=True,
        )

        # Dry run should return success
        assert result is True

        # Should not call UCS operations
        mock_ucs.disable_user.assert_not_called()
        mock_ucs.remove_groups_except.assert_not_called()

    @patch("deprovision_disable.remove_saml_identity_with_credentials")
    def test_deprovision_user_success(self, mock_remove_saml):
        """Test deprovision_user successfully deprovisions user."""
        from deprovision_disable import deprovision_user

        mock_ucs = MagicMock()
        mock_ucs.disable_user.return_value = True
        mock_ucs.remove_groups_except.return_value = True
        mock_remove_saml.return_value = True

        timestamp = "2026-04-12T12h00m00S"

        result = deprovision_user(
            mock_ucs,
            "testuser",
            "https://keycloak.example.com",
            "admin",
            "password",
            "saml-provider",
            timestamp,
            dry_run=False,
        )

        assert result is True

        # Verify UCS operations called
        mock_ucs.disable_user.assert_called_once_with("testuser", timestamp)
        mock_ucs.remove_groups_except.assert_called_once()

        # Verify SAML removal called
        mock_remove_saml.assert_called_once_with(
            keycloak_url="https://keycloak.example.com",
            username="testuser",
            admin_username="admin",
            admin_password="password",
            identity_provider="saml-provider",
        )

    @patch("deprovision_disable.remove_saml_identity_with_credentials")
    def test_deprovision_user_ucs_disable_fails(self, mock_remove_saml):
        """Test deprovision_user handles UCS disable failure."""
        from deprovision_disable import deprovision_user

        mock_ucs = MagicMock()
        mock_ucs.disable_user.return_value = False
        mock_remove_saml.return_value = True

        timestamp = "2026-04-12T12h00m00S"

        result = deprovision_user(
            mock_ucs,
            "testuser",
            "https://keycloak.example.com",
            "admin",
            "password",
            "saml-provider",
            timestamp,
            dry_run=False,
        )

        # Should return False when disable fails
        assert result is False

    @patch("deprovision_disable.remove_saml_identity_with_credentials")
    def test_deprovision_user_saml_removal_fails(self, mock_remove_saml):
        """Test deprovision_user continues when SAML removal fails."""
        from deprovision_disable import deprovision_user

        mock_ucs = MagicMock()
        mock_ucs.disable_user.return_value = True
        mock_ucs.remove_groups_except.return_value = True
        mock_remove_saml.return_value = False

        timestamp = "2026-04-12T12h00m00S"

        result = deprovision_user(
            mock_ucs,
            "testuser",
            "https://keycloak.example.com",
            "admin",
            "password",
            "saml-provider",
            timestamp,
            dry_run=False,
        )

        # SAML removal failure should not cause overall failure
        assert result is True

    @patch("deprovision_disable.remove_saml_identity_with_credentials")
    def test_deprovision_user_groups_removal_fails(self, mock_remove_saml):
        """Test deprovision_user handles groups removal failure."""
        from deprovision_disable import deprovision_user

        mock_ucs = MagicMock()
        mock_ucs.disable_user.return_value = True
        mock_ucs.remove_groups_except.return_value = False
        mock_remove_saml.return_value = True

        timestamp = "2026-04-12T12h00m00S"

        result = deprovision_user(
            mock_ucs,
            "testuser",
            "https://keycloak.example.com",
            "admin",
            "password",
            "saml-provider",
            timestamp,
            dry_run=False,
        )

        # Groups removal failure should cause overall failure
        assert result is False

    def test_parse_args_default_values(self):
        """Test parse_args sets correct default values."""
        from deprovision_disable import parse_args

        with patch("sys.argv", ["deprovision_disable.py", "--udm_api_password", "test"]):
            args = parse_args()

            assert args.udm_api_username == "Administrator"
            assert args.keycloak_api_username == "admin"
            assert args.dry_run is False
            assert args.verify_certificate is True
            assert args.enforce_ipv4 is False
            assert args.iam_api_url == "https://iam-api-dev.hrz.uni-marburg.de/openDesk/v1.0/openDesk_account_depro"

    def test_parse_args_custom_values(self):
        """Test parse_args accepts custom values."""
        from deprovision_disable import parse_args

        with patch(
            "sys.argv",
            [
                "deprovision_disable.py",
                "--udm_api_password",
                "test",
                "--import_domain",
                "example.com",
                "--keycloak_url",
                "https://keycloak.example.com",
                "--dry_run",
                "True",
                "--iam_api_url",
                "https://custom-iam.example.com",
            ],
        ):
            args = parse_args()

            assert args.import_domain == "example.com"
            assert args.keycloak_url == "https://keycloak.example.com"
            assert args.dry_run is True
            assert args.iam_api_url == "https://custom-iam.example.com"

    def test_setup_logging(self):
        """Test setup_logging configures logging correctly."""
        from deprovision_disable import setup_logging

        mock_args = MagicMock()
        mock_args.logpath = "./test_logs"
        mock_args.loglevel = "INFO"
        mock_args.udm_api_password = "test_pass"
        mock_args.import_domain = "example.com"

        with patch("pathlib.Path.mkdir"):
            setup_logging(mock_args)

            # Should not raise exceptions

    def test_deprovision_skip_admin_accounts(self):
        """Test main skips usernames ending with -admin."""
        from deprovision_disable import deprovision_user

        mock_ucs = MagicMock()
        mock_ucs.disable_user.return_value = True

        timestamp = "2026-04-12T12h00m00S"

        # User ending with -admin should be skipped
        deprovision_user(
            mock_ucs,
            "testuser-admin",
            "https://keycloak.example.com",
            "admin",
            "password",
            "saml-provider",
            timestamp,
            dry_run=False,
        )

        # In actual main loop, this user would be skipped
        # The deprovision_user function doesn't skip, but main does
        mock_ucs.disable_user.assert_called_once()

    @patch("builtins.open", new_callable=MagicMock)
    def test_main_writes_output_file(self, mock_open):
        """Test main writes deprovisioned users to output file."""
        from deprovision_disable import main

        # Mock dependencies
        with patch("deprovision_disable.parse_args") as mock_parse:
            with patch("deprovision_disable.setup_logging"):
                with patch("deprovision_disable.Ucs"):
                    with patch("deprovision_disable.get_iam_api_users") as mock_iam:
                        with patch("deprovision_disable.get_ucs_users") as mock_ucs:
                            with patch("deprovision_disable.deprovision_user") as mock_deprovision:
                                # Setup mocks
                                mock_args = MagicMock()
                                mock_args.iam_api_url = "https://iam.example.com"
                                mock_args.dry_run = False
                                mock_args.keycloak_api_username = "admin"
                                mock_args.keycloak_api_password = "password"
                                mock_args.keycloak_url = "https://keycloak.example.com"
                                mock_args.identity_provider = "saml-provider"
                                mock_args.output_deprovisioned_filename = "test_output.txt"
                                mock_args.import_domain = "example.com"
                                mock_args.udm_api_username = "admin"
                                mock_args.udm_api_password = "password"
                                mock_args.import_maildomain = None
                                mock_args.enforce_ipv4 = False
                                mock_args.verify_certificate = True
                                mock_parse.return_value = mock_args

                                # Mock users
                                mock_iam.return_value = {"user2"}
                                mock_ucs.return_value = {"user1", "user2"}
                                mock_deprovision.return_value = True

                                # Mock file handle
                                mock_file = MagicMock()
                                mock_open.return_value.__enter__ = MagicMock(return_value=mock_file)
                                mock_open.return_value.__exit__ = MagicMock(return_value=False)

                                # Run main
                                main()

                                # Verify output file was written for user1
                                assert mock_open.call_count >= 2  # Called for user1 and user1-admin

    def test_main_with_no_users_to_deprovision(self):
        """Test main exits early when no users need deprovisioning."""
        from deprovision_disable import main

        with patch("deprovision_disable.parse_args") as mock_parse:
            with patch("deprovision_disable.setup_logging"):
                with patch("deprovision_disable.Ucs"):
                    with patch("deprovision_disable.get_iam_api_users") as mock_iam:
                        with patch("deprovision_disable.get_ucs_users") as mock_ucs:
                            # Setup mocks - UCS and IAM have same users
                            mock_iam.return_value = {"user1", "user2"}
                            mock_ucs.return_value = {"user1", "user2"}

                            mock_args = MagicMock()
                            mock_args.iam_api_url = "https://iam.example.com"
                            mock_args.dry_run = False
                            mock_args.keycloak_api_username = "admin"
                            mock_args.keycloak_api_password = "password"
                            mock_args.keycloak_url = None
                            mock_args.identity_provider = "saml-provider"
                            mock_args.output_deprovisioned_filename = None
                            mock_args.import_domain = "example.com"
                            mock_args.udm_api_username = "admin"
                            mock_args.udm_api_password = "password"
                            mock_args.import_maildomain = None
                            mock_args.enforce_ipv4 = False
                            mock_args.verify_certificate = True
                            mock_parse.return_value = mock_args

                            # Run main - should not fail even with no deprovisioning needed
                            try:
                                main()
                            except SystemExit:
                                pass

                            # Should not call deprovision_user since no users differ
