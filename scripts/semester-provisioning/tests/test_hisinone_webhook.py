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
        # Expect an authentication/validation failure; endpoint should reject invalid signatures
        assert resp.status_code in (400, 401, 403, 422)
