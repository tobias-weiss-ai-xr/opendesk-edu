# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
"""HISinOne webhook receiver.

English / Deutsch bilingual docstring.
"""

from __future__ import annotations

import os
import json
import hmac
import hashlib
import logging
from typing import Any, Optional

import httpx
from fastapi import FastAPI, Request, HTTPException, status

APP_TITLE = "HISinOne Webhook Receiver"
logger = logging.getLogger("hisinone_webhook")
logging.basicConfig(level=logging.INFO)

BASE_API_URL = os.environ.get("OPENDESK_API_BASE_URL", "http://localhost:8000/api/v1")
SECRET = os.environ.get("HISINONE_WEBHOOK_SECRET", "")
API_TIMEOUT = float(os.environ.get("API_CALL_TIMEOUT_SECONDS", "5"))
AUTH_TOKEN = os.environ.get(
    "LMS_API_TOKEN"
)  # optional Bearer token for internal API calls

app = FastAPI(title=APP_TITLE)


def _get_base_groups_for_type(person_type: str) -> list[str]:
    """Map HISinOne person type to openDesk Keycloak groups."""
    mapping = {
        "student": ["managed-by-attribute-Learnmanagement", "managed-by-attribute-FileshareCloud"],
        "faculty": [
            "managed-by-attribute-Learnmanagement",
            "managed-by-attribute-Groupware",
            "managed-by-attribute-Fileshare",
            "managed-by-attribute-FileshareCloud",
            "managed-by-attribute-Knowledgemanagement",
            "managed-by-attribute-Videoconference",
            "managed-by-attribute-Livecollaboration",
            "managed-by-attribute-Projectmanagement",
        ],
        "employee": [
            "managed-by-attribute-Groupware",
            "managed-by-attribute-Fileshare",
            "managed-by-attribute-FileshareCloud",
            "managed-by-attribute-Projectmanagement",
        ],
        "alumni": [],
        "guest": [
            "managed-by-attribute-Videoconference",
            "managed-by-attribute-Livecollaboration",
        ],
    }
    return mapping.get(person_type, [])


def _get_semester_groups(role: str, semester: str) -> list[str]:
    """Generate semester-specific group names."""
    if not semester:
        return []
    return [
        f"{role}:{semester}",
        f"enrolled:{semester}",
    ]


def _verify_signature(body_bytes: bytes, signature_header: Optional[str]) -> bool:
    if not SECRET:
        # SECURITY: Fail closed when no secret is configured.
        # In production, HISINONE_WEBHOOK_SECRET must always be set.
        logger.error(
            "HISINONE_WEBHOOK_SECRET is not configured; "
            "webhook signature verification is disabled. "
            "Set the HISINONE_WEBHOOK_SECRET environment variable."
        )
        return False
    if not signature_header:
        return False
    computed = hmac.new(SECRET.encode(), body_bytes, hashlib.sha256).hexdigest()
    return hmac.compare_digest(computed, signature_header)


async def _forward_to_api(
    endpoint: str, method: str, payload: Optional[dict] = None
) -> bool:
    url = f"{BASE_API_URL}{endpoint}"
    headers = {"Content-Type": "application/json"}
    if AUTH_TOKEN:
        headers["Authorization"] = f"Bearer {AUTH_TOKEN}"
    try:
        async with httpx.AsyncClient(timeout=API_TIMEOUT) as client:
            resp = await client.request(
                method, url, json=payload or {}, headers=headers
            )
            if 200 <= resp.status_code < 300:
                return True
            logger.warning(
                f"LMS API call failed {method} {url}: {resp.status_code} {resp.text}"
            )
            return False
    except Exception as exc:
        logger.exception(f"Error calling LMS API {method} {url}: {exc}")
        return False


@app.post("/api/v1/webhooks/hisinone")
async def handle_webhook(request: Request) -> dict[str, Any]:
    body = await request.body()
    signature = request.headers.get("X-HISINONE-SIGNATURE") or request.headers.get(
        "X-HISINONE_Signature"
    )
    if not _verify_signature(body, signature):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid webhook signature"
        )

    # Parse payload
    try:
        payload = json.loads(body.decode("utf-8"))
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid JSON payload"
        )

    event_type = payload.get("event")
    data = payload.get("data") or payload

    # Map HISinOne events to internal LMS API endpoints
    if event_type == "enrollment.created":
        await _forward_to_api("/enrollments", "POST", data)
    elif event_type == "enrollment.deleted":
        enroll_id = data.get("id") or data.get("enrollment_id")
        if enroll_id:
            await _forward_to_api(f"/enrollments/{enroll_id}", "DELETE")
    elif event_type == "instructor.changed":
        instr_id = data.get("id") or data.get("instructor_id")
        if instr_id:
            changes = data.get("changes", data)
            await _forward_to_api(f"/instructors/{instr_id}", "PATCH", changes)
    elif event_type == "course.created":
        await _forward_to_api("/courses", "POST", data)
    elif event_type == "course.deleted":
        course_id = data.get("id") or data.get("course_id")
        if course_id:
            await _forward_to_api(f"/courses/{course_id}", "DELETE")

    elif event_type == "person.created":
        person_type = data.get("type", "unknown")
        username = data.get("username") or data.get("uid", "")
        email = data.get("email", "")
        first_name = data.get("firstName", "")
        last_name = data.get("lastName", "")

        logger.info(f"Lifecycle: person.created type={person_type} username={username}")

        from sync.keycloak_client import KeycloakClient, KeycloakConfig
        kc_config = KeycloakConfig.from_env()
        kc = KeycloakClient(kc_config)

        existing = kc.get_user_by_username(username)
        if existing:
            logger.info(f"User {username} already exists in Keycloak, skipping creation")
            if not existing.get("enabled", True):
                kc.enable_user(existing["id"])
                logger.info(f"Re-enabled existing user {username}")
        else:
            user_id = kc.create_user({
                "username": username,
                "email": email,
                "firstName": first_name,
                "lastName": last_name,
                "enabled": True,
                "attributes": {
                    "source": ["hisinone"],
                    "personType": [person_type],
                },
            })
            logger.info(f"Created Keycloak user {username} with ID {user_id}")

        base_groups = _get_base_groups_for_type(person_type)
        if base_groups and existing:
            kc.sync_user_groups(existing["id"], set(base_groups))

    elif event_type == "immatriculation":
        username = data.get("username") or data.get("uid", "")
        logger.info(f"Lifecycle: immatriculation username={username}")

        from sync.keycloak_client import KeycloakClient, KeycloakConfig
        kc = KeycloakClient(KeycloakConfig.from_env())

        user = kc.get_user_by_username(username)
        if not user:
            logger.warning(f"Immatriculation: user {username} not found in Keycloak")
            return {"status": "skipped", "reason": "user_not_found"}

        if not user.get("enabled", True):
            kc.enable_user(user["id"])
            logger.info(f"Re-enabled user {username} after immatriculation")

        semester = data.get("semester", "")
        semester_groups = _get_semester_groups("student", semester)
        if semester_groups:
            kc.sync_user_groups(user["id"], set(semester_groups))

    elif event_type == "exmatriculation":
        username = data.get("username") or data.get("uid", "")
        logger.info(f"Lifecycle: exmatriculation username={username}")

        from sync.keycloak_client import KeycloakClient, KeycloakConfig
        kc = KeycloakClient(KeycloakConfig.from_env())

        user = kc.get_user_by_username(username)
        if not user:
            logger.warning(f"Exmatriculation: user {username} not found")
            return {"status": "skipped", "reason": "user_not_found"}

        base_groups = set(_get_base_groups_for_type("alumni"))
        kc.sync_user_groups(user["id"], base_groups)

        kc.disable_user(user["id"])
        logger.info(f"Disabled user {username} after exmatriculation")

    elif event_type == "leave_of_absence":
        username = data.get("username") or data.get("uid", "")
        logger.info(f"Lifecycle: leave_of_absence username={username}")

        from sync.keycloak_client import KeycloakClient, KeycloakConfig
        kc = KeycloakClient(KeycloakConfig.from_env())

        user = kc.get_user_by_username(username)
        if not user:
            logger.warning(f"LOA: user {username} not found")
            return {"status": "skipped", "reason": "user_not_found"}

        kc.update_user(user["id"], {
            "attributes": {
                **(user.get("attributes") or {}),
                "suspended": ["true"],
                "suspendedAt": [__import__('datetime').datetime.utcnow().isoformat()],
            }
        })
        logger.info(f"Suspended user {username} (leave of absence)")

    elif event_type == "role_change":
        username = data.get("username") or data.get("uid", "")
        new_role = data.get("newRole", "")
        logger.info(f"Lifecycle: role_change username={username} newRole={new_role}")

        from sync.keycloak_client import KeycloakClient, KeycloakConfig
        kc = KeycloakClient(KeycloakConfig.from_env())

        user = kc.get_user_by_username(username)
        if not user:
            logger.warning(f"Role change: user {username} not found")
            return {"status": "skipped", "reason": "user_not_found"}

        groups = _get_base_groups_for_type(new_role)
        if groups:
            kc.sync_user_groups(user["id"], set(groups))
            logger.info(f"Updated groups for {username} to role {new_role}: {groups}")

    else:
        logger.info(f"Unhandled HISinOne event: {event_type}")

    return {"status": "processed", "event": event_type}
