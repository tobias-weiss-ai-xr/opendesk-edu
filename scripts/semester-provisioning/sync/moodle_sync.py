#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

"""
Moodle sync adapter for Keycloak roles.

EN: Maps Keycloak roles to Moodle roles and provides a hook to enroll groups.
DE: Mapper von Keycloak-Rollen zu Moodle-Rollen und Hook zur Gruppensynchronisation.
"""

from typing import Dict, Optional


class MoodleSyncAdapter:
    """Translate Keycloak roles to Moodle roles and synchronize groups.

    EN: Simple adapter used by the Role Sync Engine. In tests this class is
    typically replaced with a dummy implementation.
    DE: Ein simpler Adapter, der Rollen von Keycloak in Moodle-Rollen übersetzt und
    Gruppen synchronisiert. In Tests wird diese Klasse üblicherweise durch eine
    Dummy-Implementierung ersetzt.
    """

    def __init__(self, role_mapping: Dict[str, str]) -> None:
        self.role_mapping = role_mapping

    def map_role(self, keycloak_role: str) -> Optional[str]:
        return self.role_mapping.get(keycloak_role)

    def sync_group_to_role(self, group_name: str, moodle_role: str) -> None:
        """Sync a Keycloak group to a given Moodle role."""
        _ = (group_name, moodle_role)
