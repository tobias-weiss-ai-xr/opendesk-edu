"""Bulk HISinOne export sync utility.
# SPDX-License-Identifier: MIT

- SPDX-License-Identifier: MIT
- English / Deutsch bilingual docstring.
"""

from __future__ import annotations

import os
import csv
import json
import argparse
import logging
from datetime import datetime, timezone
from pathlib import Path

import httpx

BASE_API_URL = os.environ.get("OPENDESK_API_BASE_URL", "http://localhost:8000/api/v1")
LOG_DIR = Path("logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("hisinone_bulk_sync")

API_TIMEOUT = float(os.environ.get("API_CALL_TIMEOUT_SECONDS", "5"))
AUTH_TOKEN = os.environ.get("LMS_API_TOKEN")


def _post(endpoint: str, payload: dict, token: str | None = None) -> bool:
    url = f"{BASE_API_URL}{endpoint}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        resp = httpx.post(url, json=payload, headers=headers, timeout=API_TIMEOUT)
        if 200 <= resp.status_code < 300:
            return True
        logger.warning(f"Failed POST {url}: {resp.status_code} {resp.text}")
        return False
    except Exception as e:
        logger.exception(f"Error POST {url}: {e}")
        return False


def _read_csv(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(dict(row))
    return rows


def _read_json(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and "courses" in data:
        return data["courses"]
    return [data]


def _parse_export(path: Path) -> list[dict]:
    if path.suffix.lower() == ".csv":
        return _read_csv(path)
    if path.suffix.lower() in {".json"}:
        return _read_json(path)
    raise ValueError("Unsupported export format. Use CSV or JSON.")


def main(export_path: Path) -> None:
    export_path = export_path.resolve()
    if not export_path.exists():
        raise SystemExit(f"Export file not found: {export_path}")
    courses = _parse_export(export_path)

    total = len(courses)
    success = 0
    failures = 0
    log_file = (
        LOG_DIR
        / f"bulk_sync_{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.log"
    )
    with log_file.open("w", encoding="utf-8") as lf:
        lf.write(f"Total records: {total}\n")
        for idx, course in enumerate(courses, start=1):
            course_payload = {
                "code": course.get("code") or course.get("course_code"),
                "title": course.get("title") or course.get("name"),
                "description": course.get("description", ""),
                "start_date": course.get("start_date"),
                "end_date": course.get("end_date"),
            }
            ok = _post("/courses", course_payload, AUTH_TOKEN)
            if not ok:
                failures += 1
                lf.write(f"[{idx}] Failed to create course: {course_payload}\n")
                continue
            # Enrollments for course, if provided
            enrollments = course.get("enrollments") or []
            course_id = course_payload.get("code")
            for en_idx, enrollment in enumerate(enrollments, start=1):
                enroll_payload = {
                    "course_code": course_payload.get("code"),
                    "user_id": enrollment.get("user_id")
                    or enrollment.get("student_id"),
                    "role": enrollment.get("role", "student"),
                }
                if not _post("/enrollments", enroll_payload, AUTH_TOKEN):
                    failures += 1
                    lf.write(f"[{idx}.{en_idx}] Failed to enroll: {enrollment}\n")
                    continue
            success += 1
            lf.write(
                f"[{idx}] Created course and enrollments: {course_payload.get('code')}\n"
            )

    logging.info(
        f"Bulk HISinOne sync complete. Total={total}, Success={success}, Failures={failures}"
    )
    logger.info(log_file.read_text())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bulk HISinOne export sync to LMS")
    parser.add_argument(
        "export", type=str, help="Path to HISinOne export CSV or JSON file"
    )
    args = parser.parse_args()
    main(Path(args.export))
