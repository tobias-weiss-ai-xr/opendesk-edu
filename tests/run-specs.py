#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
ICS Integration Test Spec Executor

Reads declarative YAML test specs from tests/specs/*.yaml and executes
them against the live cluster, validating HTTP responses against
expected behaviors.

Usage:
    python tests/run-specs.py                         # Run all specs
    python tests/run-specs.py tests/specs/ics-routing.yaml  # Single spec
    python tests/run-specs.py --format json            # JSON output
    python tests/run-specs.py --format junit           # JUnit XML output
"""

import os
import sys
import json
import yaml
import requests
import argparse
import glob
from datetime import datetime, timezone
from urllib.parse import urljoin

try:
    import jsonschema
    HAS_JSONSCHEMA = True
except ImportError:
    HAS_JSONSCHEMA = False

# ---------------------------------------------------------------------------
# Reporting constants (matching tests/lib/report.sh)
# ---------------------------------------------------------------------------

PASS = "PASS"
FAIL = "FAIL"
WARN = "WARN"
SKIP = "SKIP"

GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
NC = "\033[0m"

PASS_ICON = "\u2713"
FAIL_ICON = "\u2717"
WARN_ICON = "\u26a0"


SPEC_SCHEMA = {
    "type": "object",
    "required": ["name", "version", "services"],
    "additionalProperties": False,
    "properties": {
        "name": {"type": "string", "minLength": 1},
        "description": {"type": "string"},
        "version": {"type": "integer", "minimum": 1},
        "base_url": {"type": "string", "format": "uri"},
        "auth": {
            "type": "string",
            "enum": ["none", "session", "oidc", "saml"],
        },
        "services": {
            "type": "object",
            "additionalProperties": False,
            "patternProperties": {
                "^[a-z][a-z0-9-]*$": {
                    "type": "object",
                    "required": ["route", "tests"],
                    "additionalProperties": False,
                    "properties": {
                        "route": {"type": "string", "minLength": 1},
                        "backend": {"type": "string"},
                        "auth": {
                            "type": "string",
                            "enum": ["none", "session", "oidc", "saml"],
                        },
                        "tests": {
                            "type": "array",
                            "minItems": 1,
                            "items": {
                                "type": "object",
                                "required": ["scenario", "steps"],
                                "additionalProperties": False,
                                "properties": {
                                    "scenario": {
                                        "type": "string", "minLength": 1,
                                    },
                                    "auth": {
                                        "type": "string",
                                        "enum": [
                                            "none", "session", "oidc", "saml",
                                        ],
                                    },
                                    "steps": {
                                        "type": "array",
                                        "minItems": 1,
                                        "items": {
                                            "type": "object",
                                            "required": ["request", "expect"],
                                            "additionalProperties": False,
                                            "properties": {
                                                "request": {
                                                    "type": "object",
                                                    "required": ["method"],
                                                    "additionalProperties": False,
                                                    "properties": {
                                                        "method": {
                                                            "type": "string",
                                                            "enum": [
                                                                "GET", "POST",
                                                                "PUT", "DELETE",
                                                                "PATCH", "HEAD",
                                                                "OPTIONS",
                                                            ],
                                                        },
                                                        "path": {
                                                            "type": "string",
                                                        },
                                                        "headers": {
                                                            "type": "object",
                                                        },
                                                        "body": {"type": "string"},
                                                    },
                                                },
                                                "expect": {
                                                    "type": "object",
                                                    "additionalProperties": False,
                                                    "properties": {
                                                        "status": {
                                                            "oneOf": [
                                                                {
                                                                    "type": "integer",
                                                                },
                                                                {
                                                                    "type": "array",
                                                                    "items": {
                                                                        "type": "integer",
                                                                    },
                                                                    "minItems": 1,
                                                                },
                                                            ],
                                                        },
                                                        "redirect_contains": {
                                                            "type": "string",
                                                        },
                                                        "headers": {
                                                            "type": "object",
                                                            "additionalProperties": {
                                                                "oneOf": [
                                                                    {
                                                                        "type": "string",
                                                                    },
                                                                    {
                                                                        "type": "object",
                                                                        "required": [
                                                                            "value",
                                                                        ],
                                                                        "additionalProperties": False,
                                                                        "properties": {
                                                                            "value": {
                                                                                "type": "string",
                                                                            },
                                                                            "soft_fail": {
                                                                                "type": "boolean",
                                                                            },
                                                                        },
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                        "body_contains": {
                                                            "type": "string",
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}


def validate_spec(spec_path):
    if not HAS_JSONSCHEMA:
        print("jsonschema not installed. Install with: pip install jsonschema",
              file=sys.stderr)
        return False

    with open(spec_path, "r") as f:
        spec = yaml.safe_load(f)

    errors = sorted(
        jsonschema.Draft202012Validator(SPEC_SCHEMA).iter_errors(spec),
        key=lambda e: list(e.path),
    )

    if not errors:
        print(f"{PASS_ICON} {spec_path}: valid")
        return True

    print(f"{FAIL_ICON} {spec_path}:")
    for err in errors:
        path = ".".join(str(p) for p in err.absolute_path) or "(root)"
        print(f"    {path}: {err.message}")
    return False

# ---------------------------------------------------------------------------
# Auth resolvers
# ---------------------------------------------------------------------------


class AuthResolver:
    """Acquires authentication for test scenarios."""

    def __init__(self):
        self._token_cache = {}

    def resolve(self, auth_type, config, service_name=None):
        if auth_type is None or auth_type == "none":
            return {}
        if auth_type in ("session", "oidc"):
            return self._resolve_oidc_session(config, service_name)
        if auth_type == "saml":
            self._warn(f"SAML auth not yet implemented for {service_name}, "
                       f"falling back to unauthenticated")
            return {}
        self._warn(f"Unknown auth type '{auth_type}', treating as none")
        return {}

    @staticmethod
    def _warn(msg):
        print(f"{WARN_ICON} {msg}", file=sys.stderr)

    def _resolve_oidc_session(self, config, service_name=None):
        keycloak_host = os.getenv("KEYCLOAK_HOST", "id.opendesk.hrz.uni-marburg.de")
        realm = os.getenv("KEYCLOAK_REALM", "opendesk")
        username = os.getenv("PORTAL_USERNAME", "")
        password = os.getenv("PORTAL_PASSWORD", "")
        client_id = os.getenv("OIDC_CLIENT_ID", "opendesk-intercom")
        client_secret = os.getenv("OIDC_CLIENT_SECRET", "")
        ics_base = os.getenv("ICS_BASE_URL", "https://ics.opendesk.hrz.uni-marburg.de")

        if not username or not password:
            self._warn("PORTAL_USERNAME/PASSWORD not set, "
                       "session auth unavailable")
            return {}

        cache_key = f"{keycloak_host}/{realm}/{username}:session"
        if cache_key in self._token_cache:
            cookies = self._token_cache[cache_key]
            if cookies:
                return {"Cookie": "; ".join(f"{k}={v}" for k, v in cookies.items())}
            return {}

        self._warn("ICS requires SAML-brokered auth via browser. "
                    "Run authenticated scenarios with: "
                    "npx playwright test tests/playwright/ics-auth.spec.js")
        return {}


# ---------------------------------------------------------------------------
# Expectation validator
# ---------------------------------------------------------------------------


def validate_expectation(expect, response):
    errors = []

    if "status" in expect:
        expected_status = expect["status"]
        if isinstance(expected_status, int):
            expected_status = [expected_status]
        if response.status_code not in expected_status:
            errors.append(
                f"Expected status {expected_status}, got {response.status_code}"
            )

    if "redirect_contains" in expect:
        location = response.headers.get("Location", "")
        if expect["redirect_contains"] not in location:
            errors.append(
                f"Expected redirect containing "
                f"'{expect['redirect_contains']}', got '{location[:100]}'"
            )

    if "headers" in expect:
        for header, expected_value in expect["headers"].items():
            actual = response.headers.get(header, "")
            if isinstance(expected_value, dict):
                actual_value = expected_value.get("value", "present")
                soft_fail = expected_value.get("soft_fail", False)
            else:
                actual_value = expected_value
                soft_fail = False

            if actual_value == "present":
                if not actual:
                    if soft_fail:
                        continue
                    errors.append(f"Expected header '{header}' to be present")
            else:
                if actual != actual_value:
                    if soft_fail:
                        continue
                    errors.append(
                        f"Expected header '{header}' = '{actual_value}', "
                        f"got '{actual}'"
                    )

    if "body_contains" in expect:
        if expect["body_contains"] not in response.text:
            errors.append(
                f"Expected body to contain '{expect['body_contains']}'"
            )

    return errors


# ---------------------------------------------------------------------------
# Spec executor
# ---------------------------------------------------------------------------


def run_spec(spec_path, auth_resolver, format="table"):
    with open(spec_path, "r") as f:
        spec = yaml.safe_load(f)

    spec_name = spec.get("name", spec_path)
    base_url = os.getenv("ICS_BASE_URL", spec.get("base_url", ""))
    default_auth = spec.get("auth", "none")

    results = []

    for service_name, service_config in spec.get("services", {}).items():
        route = service_config.get("route", "/")
        service_auth = service_config.get("auth", default_auth)

        for test in service_config.get("tests", []):
            scenario = test.get("scenario", "Unnamed scenario")
            auth_type = test.get("auth", service_auth)
            steps = test.get("steps", [])

            step_results = []
            auth_headers = auth_resolver.resolve(
                auth_type, spec, service_name
            )

            for step in steps:
                request_def = step.get("request", {})
                method = request_def.get("method", "GET").upper()
                path = request_def.get("path", "/")
                url = base_url.rstrip("/") + path

                try:
                    resp = requests.request(
                        method,
                        url,
                        headers=auth_headers,
                        allow_redirects=False,
                        timeout=15,
                    )
                except requests.RequestException as e:
                    step_results.append({
                        "status": "ERROR",
                        "errors": [str(e)],
                    })
                    continue

                expect = step.get("expect", {})
                errors = validate_expectation(expect, resp)

                if errors:
                    step_results.append({
                        "status": FAIL,
                        "errors": errors,
                        "received_status": resp.status_code,
                        "received_headers": dict(resp.headers),
                    })
                else:
                    step_results.append({
                        "status": PASS,
                        "received_status": resp.status_code,
                    })

            all_pass = all(r["status"] == PASS for r in step_results)
            overall = PASS if all_pass else FAIL

            results.append({
                "service": service_name,
                "scenario": scenario,
                "auth": auth_type,
                "status": overall,
                "steps": step_results,
            })

    return spec_name, results


# ---------------------------------------------------------------------------
# Formatters
# ---------------------------------------------------------------------------


def print_table(spec_name, results):
    print(f"\n{BLUE}{'=' * 70}{NC}")
    print(f"{BLUE}Spec: {spec_name}{NC}")
    print(f"{BLUE}{'=' * 70}{NC}")

    total = len(results)
    passed = sum(1 for r in results if r["status"] == PASS)
    failed = total - passed

    for r in results:
        icon = PASS_ICON if r["status"] == PASS else FAIL_ICON
        color = GREEN if r["status"] == PASS else RED
        print(f"\n  {color}{icon} {r['service']}: {r['scenario']}{NC}")
        for step in r["steps"]:
            if step["status"] == PASS:
                print(f"    {GREEN}{PASS_ICON} "
                      f"Step: HTTP {step['received_status']}{NC}")
            else:
                for err in step.get("errors", []):
                    print(f"    {RED}{FAIL_ICON} {err}{NC}")

    print(f"\n{BLUE}{'=' * 70}{NC}")
    print(f"Total: {total}  "
          f"{GREEN}Passed: {passed}{NC}  "
          f"{RED}Failed: {failed}{NC}")
    print(f"{BLUE}{'=' * 70}{NC}\n")

    return passed, failed


def print_json(spec_name, results):
    output = {
        "spec": spec_name,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "results": results,
        "summary": {
            "total": len(results),
            "passed": sum(1 for r in results if r["status"] == PASS),
            "failed": sum(1 for r in results if r["status"] == FAIL),
        },
    }
    print(json.dumps(output, indent=2))


def print_junit(spec_name, results):
    total = len(results)
    failures = sum(1 for r in results if r["status"] == FAIL)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")

    print('<?xml version="1.0" encoding="UTF-8"?>')
    print(f'<testsuite name="{spec_name}" tests="{total}" '
          f'failures="{failures}" timestamp="{ts}">')
    for r in results:
        classname = f"ics.{r['service']}"
        name = r["scenario"]
        if r["status"] == PASS:
            print(f'  <testcase classname="{classname}" name="{name}" />')
        else:
            errors = "; ".join(
                e for s in r["steps"] for e in s.get("errors", [])
            )
            print(f'  <testcase classname="{classname}" name="{name}">')
            print(f"    <failure message=\"{errors}\" />")
            print(f"  </testcase>")
    print("</testsuite>")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="ICS Integration Test Spec Executor"
    )
    parser.add_argument(
        "specs",
        nargs="*",
        default=[],
        help="Spec files to run (default: tests/specs/*.yaml)",
    )
    parser.add_argument(
        "--format",
        choices=["table", "json", "junit"],
        default="table",
        help="Output format (default: table)",
    )
    parser.add_argument(
        "--spec-dir",
        default=os.path.join(
            os.path.dirname(__file__), "specs"
        ),
        help="Directory containing spec files",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate spec files against JSON schema without executing",
    )
    args = parser.parse_args()

    if args.specs:
        spec_files = args.specs
    else:
        spec_files = sorted(glob.glob(os.path.join(args.spec_dir, "*.yaml")))

    if not spec_files:
        print(f"No spec files found in {args.spec_dir}")
        sys.exit(0)

    if args.validate:
        all_valid = True
        for spec_path in spec_files:
            if not validate_spec(spec_path):
                all_valid = False
        sys.exit(0 if all_valid else 1)

    auth_resolver = AuthResolver()
    total_passed = 0
    total_failed = 0

    for spec_path in spec_files:
        spec_name, results = run_spec(
            spec_path, auth_resolver, args.format
        )

        if args.format == "table":
            p, f = print_table(spec_name, results)
        elif args.format == "json":
            print_json(spec_name, results)
            p = sum(1 for r in results if r["status"] == PASS)
            f = len(results) - p
        elif args.format == "junit":
            print_junit(spec_name, results)
            p = sum(1 for r in results if r["status"] == PASS)
            f = len(results) - p

        total_passed += p
        total_failed += f

    if args.format == "table" and len(spec_files) > 1:
        print(f"\n{BLUE}{'=' * 70}{NC}")
        print(f"All specs: {total_passed + total_failed} scenarios  "
              f"{GREEN}Passed: {total_passed}{NC}  "
              f"{RED}Failed: {total_failed}{NC}")
        print(f"{BLUE}{'=' * 70}{NC}")

    sys.exit(1 if total_failed > 0 else 0)


if __name__ == "__main__":
    main()
