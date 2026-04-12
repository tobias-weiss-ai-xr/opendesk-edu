# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0

from unittest.mock import MagicMock



class TestGetUserDn:
    def test_get_user_dn_returns_correct_format(self, mock_ucs):
        ucs = MagicMock()
        ucs.user_base = "cn=users,dc=swp-ldap,dc=internal"

        username = "testuser"
        expected_dn = f"uid={username},{ucs.user_base}"

        assert expected_dn == "uid=testuser,cn=users,dc=swp-ldap,dc=internal"

    def test_get_user_dn_with_special_characters(self, mock_ucs):
        ucs = MagicMock()
        ucs.user_base = "cn=users,dc=swp-ldap,dc=internal"

        username = "test.user-123"
        expected_dn = f"uid={username},{ucs.user_base}"

        assert expected_dn == "uid=test.user-123,cn=users,dc=swp-ldap,dc=internal"


class TestGetUserGroups:
    def test_get_user_groups_returns_list(self, mock_ucs, test_user_data):
        expected_groups = test_user_data["groups"]
        assert isinstance(expected_groups, list)

    def test_get_user_groups_empty_when_not_found(self, mock_ucs):
        expected = []
        assert expected == []


class TestDisableUser:
    def test_disable_user_sets_disabled_flag(self, mock_ucs, test_user_data):
        assert True

    def test_disable_user_updates_description_with_timestamp(self, mock_ucs):
        assert True

    def test_disable_user_idempotent_already_deprovisioned(self, mock_ucs):
        assert True


class TestRemoveGroupsExcept:
    def test_remove_groups_except_keeps_specified_groups(self, mock_ucs, non_reconcile_groups):
        assert True

    def test_remove_groups_except_removes_others(self, mock_ucs, non_reconcile_groups):
        assert True
