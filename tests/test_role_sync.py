#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

"""Unit tests for the Role Synchronization Engine.

EN: Tests ensure Keycloak roles are mapped to LMS roles and that group-enrollment
calls are issued for both ILIAS and Moodle with proper audit logging.
DE: Tests sichern, dass Keycloak-Rollen korrekt zu LMS-Rollen gemappt werden und
Gruppeneinschreibungen für ILIAS und Moodle ausgelöst werden, inklusive Audit-Logs.
"""

from pathlib import Path
import importlib.util

ROOT = Path(__file__).resolve().parents[1]
ROLE_SYNC_PATH = ROOT / "scripts/semester-provisioning/sync/role_sync.py"


def _load_module(module_name: str, file_path: Path):
    spec = importlib.util.spec_from_file_location(module_name, str(file_path))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # type: ignore
    return module


def test_role_sync_engine_triggers_expected_calls():
    # Dynamic load of modules to avoid Python package import issues due to hyphenated paths
    kc_mod = _load_module(
        "kc", ROOT / "scripts/semester-provisioning/sync/keycloak_client.py"
    )
    role_sync_mod = _load_module("role_sync", ROLE_SYNC_PATH)

    # Create fake KeycloakRole-like objects with 'name' attribute
    from types import SimpleNamespace

    roles = [
        SimpleNamespace(name="student"),
        SimpleNamespace(name="tutor"),
        SimpleNamespace(name="lecturer"),
    ]
    groups = ["campus-a", "campus-b"]

    class FakeKcClient:
        def __init__(self, roles, groups):
            self._roles = roles
            self._groups = groups

        def get_roles(self):
            return self._roles

        def get_groups(self):
            return self._groups

    kc = FakeKcClient(roles, groups)

    ilias_mapping = {"student": "student", "tutor": "tutor", "lecturer": "lecturer"}
    moodle_mapping = {
        "student": "student",
        "tutor": "editingteacher",
        "lecturer": "editingteacher",
    }

    # Create simple adapters that record calls
    class RecorderAdapter:
        def __init__(self, mapping):
            self.mapping = mapping
            self.sync_calls = []

        def map_role(self, keycloak_role: str):
            return self.mapping.get(keycloak_role)

        def sync_group_to_role(self, group_name: str, role: str) -> None:
            self.sync_calls.append((group_name, role))

    ilias = RecorderAdapter(ilias_mapping)
    moodle = RecorderAdapter(moodle_mapping)

    class MemoryAuditLogger:
        def __init__(self):
            self.entries = []

        def log(self, message: str) -> None:
            self.entries.append(message)

    logger = MemoryAuditLogger()

    engine = role_sync_mod.RoleSyncEngine(kc, ilias, moodle, audit_logger=logger)
    engine.sync()

    total_calls = len(ilias.sync_calls) + len(moodle.sync_calls)
    assert total_calls == 12
    assert ilias.sync_calls[0] == ("campus-a", "student")
    assert moodle.sync_calls[1] == ("campus-a", "editingteacher")
    assert len(logger.entries) == 12
