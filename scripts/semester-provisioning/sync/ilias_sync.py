#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

"""
ILIAS sync adapter for Keycloak roles.

EN: Maps Keycloak roles to ILIAS roles and provides a hook to enroll groups.
DE: Mapper von Keycloak-Rollen zu ILIAS-Rollen und Hook zum Anlegen von Gruppen.
"""

from typing import Dict, Optional


class ILIASSyncAdapter:
    """Translate Keycloak roles to ILIAS roles and synchronize groups.

    EN: Simple adapter used by the Role Sync Engine. In tests this class is
    typically replaced with a dummy implementation.
    DE: Ein einfacher Adapter, der Rollen von Keycloak in ILIAS-Rollen übersetzt und
    Gruppen synchronisiert. In Tests wird diese Klasse üblicherweise durch eine
    Dummy-Implementierung ersetzt.
    """

    def __init__(self, role_mapping: Dict[str, str]) -> None:
        self.role_mapping = role_mapping

    def map_role(self, keycloak_role: str) -> Optional[str]:
        return self.role_mapping.get(keycloak_role)

    def sync_group_to_role(self, group_name: str, ilias_role: str) -> None:
        """Sync a Keycloak group to a given ILIAS role.

        EN: In real implementation this would call ILIAS APIs. Here we provide
        a hook that can be overridden/mocked in tests.
        DE: In der echten Implementierung würden hier ILIAS-APIs aufgerufen. Hier
        wird eine Hook bereitgestellt, die in Tests gemockt werden kann.
        """
        # Placeholder for production integration
        _ = (group_name, ilias_role)
