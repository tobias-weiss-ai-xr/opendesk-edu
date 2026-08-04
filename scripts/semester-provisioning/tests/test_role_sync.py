import importlib.util
import pathlib


def load_role_sync_module():
    root = pathlib.Path(__file__).resolve().parents[3]
    module_path = root / "scripts" / "semester-provisioning" / "sync" / "role_sync.py"
    spec = importlib.util.spec_from_file_location("role_sync", str(module_path))
    mod = importlib.util.module_from_spec(spec)  # type: ignore
    spec.loader.exec_module(mod)  # type: ignore
    return mod


def test_basic_role_sync_maps_student(monkeypatch):
    role_sync = load_role_sync_module()

    class FakeLMS:
        def __init__(self):
            self.calls = []

        def set_user_roles(self, user_id, roles):
            self.calls.append((user_id, roles))

    fake_lms = FakeLMS()
    engine = role_sync.RoleSyncEngine(lms_client=fake_lms)

    KCUser = role_sync.KCUser
    LMSUser = role_sync.LMSUser
    # Pydantic requires model_rebuild() when models are loaded via importlib
    # to resolve forward references and type annotations
    KCUser.model_rebuild()
    LMSUser.model_rebuild()
    kc_users = [KCUser(id="u1", realm_roles=["student"])]

    results = engine.sync(kc_users)

    assert len(results) == 1
    assert isinstance(results[0], LMSUser)
    assert results[0].id == "u1"
    assert results[0].roles == ["student"]
    assert fake_lms.calls == [("u1", ["student"])]


def test_role_sync_ignores_unmapped_role_and_maps_instructor(monkeypatch):
    role_sync = load_role_sync_module()

    class FakeLMS:
        def __init__(self):
            self.calls = []

        def set_user_roles(self, user_id, roles):
            self.calls.append((user_id, roles))

    fake_lms = FakeLMS()
    engine = role_sync.RoleSyncEngine(lms_client=fake_lms)

    KCUser = role_sync.KCUser
    kc_users = [KCUser(id="u2", realm_roles=["lecturer"])]

    results = engine.sync(kc_users)

    assert len(results) == 1
    assert results[0].id == "u2"
    assert results[0].roles == ["instructor"]
    assert fake_lms.calls == [("u2", ["instructor"])]
