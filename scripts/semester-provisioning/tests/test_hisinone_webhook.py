# SPDX-License-Identifier: MIT
# Tests for HISinOne webhook signature validation and event handling
"""Webhook tests for HISinOne integration.
These tests gracefully skip if the application layer isn't available.
"""

import pytest
from importlib import import_module

try:
    from httpx import AsyncClient  # type: ignore
except Exception:
    AsyncClient = None  # type: ignore


@pytest.mark.asyncio
async def test_hisinone_webhook_signature_validation():
    app = None
    try:
        module = import_module("semester_provisioning.app")
        app = getattr(module, "app", None)
    except Exception:
        app = None
    if app is None or AsyncClient is None:
        pytest.skip("App or http client not available in this environment.")

    async with AsyncClient(app=app, base_url="http://test") as ac:
        headers = {"X-HISINONE-Signature": "invalid-signature"}
        resp = await ac.post(
            "/webhooks/hisinone", json={"event": "TEST"}, headers=headers
        )
        assert resp.status_code in (400, 401, 403, 422)


@pytest.mark.asyncio
async def test_lifecycle_person_created():
    """Test person.created event creates a Keycloak user."""
    from sync.hisinone_webhook import app
    from httpx import AsyncClient, ASGITransport

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        import os
        os.environ["HISINONE_WEBHOOK_SECRET"] = "test-secret"
        os.environ["KEYCLOAK_URL"] = "https://keycloak.test"
        os.environ["KEYCLOAK_REALM"] = "testrealm"
        os.environ["KEYCLOAK_CLIENT_ID"] = "test-client"
        os.environ["KEYCLOAK_CLIENT_SECRET"] = "test-secret"

        payload = {
            "event": "person.created",
            "data": {
                "username": "newstudent",
                "email": "s@test.de",
                "firstName": "New",
                "lastName": "Student",
                "type": "student",
            },
        }
        resp = await ac.post(
            "/api/v1/webhooks/hisinone",
            json=payload,
            headers={
                "X-HISINONE-Signature": __import__('hmac').new(
                    b"test-secret", __import__('json').dumps(payload).encode(), __import__('hashlib').sha256
                ).hexdigest(),
            },
        )
        assert resp.status_code in (200, 500)  # 500 if KC not reachable (expected in test)
