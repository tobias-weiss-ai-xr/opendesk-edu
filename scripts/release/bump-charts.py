#!/usr/bin/env python3
"""Bump Helm chart versions based on conventional commits since last tag.

Groups commits by chart directory scope, determines semver bumps:
  feat → minor | fix → patch | BREAKING CHANGE → major
  docs/style/refactor/ci/chore → no bump

Usage:
  ./bump-charts.py [--dry-run] [--tag TAG]
"""

import argparse
import os
import re
import subprocess
import sys
from typing import Optional

CHARTS_DIR = "helmfile/charts"
CHART_SCOPES = {
    chart: os.path.join(CHARTS_DIR, chart)
    for chart in os.listdir(CHARTS_DIR)
    if os.path.isdir(os.path.join(CHARTS_DIR, chart))
}


def run_git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()


def get_commits_since(tag: Optional[str] = None) -> list[dict]:
    if tag:
        log = run_git("log", f"{tag}..HEAD", "--format=%H%n%s%n%b===")
    else:
        log = run_git("log", "--format=%H%n%s%n%b===")
    commits = []
    for entry in log.split("===\n"):
        entry = entry.strip()
        if not entry:
            continue
        lines = entry.split("\n", 2)
        if len(lines) < 2:
            continue
        hash_ = lines[0]
        subject = lines[1]
        body = lines[2] if len(lines) > 2 else ""
        commits.append({"hash": hash_, "subject": subject, "body": body})
    return commits


def parse_conventional_commit(subject: str) -> tuple[Optional[str], Optional[str], bool]:
    """Parse conventional commit: type(scope): description | type!: ..."""
    m = re.match(r"^(\w+)(?:\(([^)]*)\))?(!)?\s*:\s*(.+)$", subject)
    if not m:
        return None, None, False
    return m.group(1), m.group(2) or None, bool(m.group(3))


DEFAULT_SCOPE = "__repo__"


def determine_chart_scope(scope: Optional[str], body: str) -> Optional[str]:
    """Map conventional commit scope to a chart directory name."""
    if scope is None:
        return DEFAULT_SCOPE
    if scope in CHART_SCOPES:
        return scope
    for chart_name in CHART_SCOPES:
        if chart_name.startswith(scope) or scope.startswith(chart_name):
            return chart_name
    return None


def get_current_version(chart: str) -> list[int]:
    path = os.path.join(CHARTS_DIR, chart, "Chart.yaml")
    with open(path) as f:
        for line in f:
            m = re.match(r"^version:\s*(\d+)\.(\d+)\.(\d+)", line)
            if m:
                return [int(m.group(1)), int(m.group(2)), int(m.group(3))]
    return [0, 1, 0]


def write_version(chart: str, version: list[int]) -> None:
    path = os.path.join(CHARTS_DIR, chart, "Chart.yaml")
    new_ver = f"{version[0]}.{version[1]}.{version[2]}"
    with open(path) as f:
        content = f.read()
    content = re.sub(r"^version:\s*\d+\.\d+\.\d+", f"version: {new_ver}", content, count=1, flags=re.MULTILINE)
    with open(path, "w") as f:
        f.write(content)
    print(f"  {chart}: 0.1.0 → {new_ver}")


def bump_version(current: list[int], bump_type: str) -> list[int]:
    v = current.copy()
    if bump_type == "major":
        v[0] += 1
        v[1] = 0
        v[2] = 0
    elif bump_type == "minor":
        v[1] += 1
        v[2] = 0
    elif bump_type == "patch":
        v[2] += 1
    return v


def main() -> None:
    parser = argparse.ArgumentParser(description="Bump chart versions from conventional commits")
    parser.add_argument("--dry-run", action="store_true", help="Print changes without modifying files")
    parser.add_argument("--tag", type=str, default=None, help="Tag to compare against (default: latest)")
    args = parser.parse_args()

    tag = args.tag
    if tag is None:
        try:
            tag = run_git("describe", "--tags", "--abbrev=0")
            print(f"Bumping from tag: {tag}")
        except subprocess.CalledProcessError:
            tag = None
            print("No tags found, scanning full history")

    commits = get_commits_since(tag)
    chart_bumps: dict[str, str] = {}
    commit_types_nobump = {"docs", "style", "refactor", "test", "build", "ci", "chore", "revert"}
    breaking_scopes: set[str] = set()

    for c in commits:
        ctype, cscope, is_breaking = parse_conventional_commit(c["subject"])
        if ctype is None:
            continue
        if is_breaking or "BREAKING CHANGE" in c["body"]:
            scope = determine_chart_scope(cscope, c["body"]) or DEFAULT_SCOPE
            breaking_scopes.add(scope)
        scope = determine_chart_scope(cscope, c["body"])
        if scope is None:
            continue
        current_bump = chart_bumps.get(scope, "none")
        if ctype == "feat":
            if current_bump not in ("major",):
                chart_bumps[scope] = "minor"
        elif ctype == "fix":
            if current_bump not in ("major", "minor"):
                chart_bumps[scope] = "patch"
        elif ctype in commit_types_nobump:
            continue
        else:
            if current_bump == "none":
                chart_bumps[scope] = "patch"

    for scope in breaking_scopes:
        chart_bumps[scope] = "major"

    repo_scopes = [s for s in chart_bumps if s == DEFAULT_SCOPE]
    chart_scopes = [s for s in chart_bumps if s in CHART_SCOPES]

    if args.dry_run:
        print("\nWould bump:")
        if repo_scopes:
            print(f"  {DEFAULT_SCOPE}: {chart_bumps[DEFAULT_SCOPE]}")
        for chart in sorted(chart_scopes):
            ver = get_current_version(chart)
            new_ver = bump_version(ver, chart_bumps[chart])
            print(f"  {chart}: {'.'.join(map(str, ver))} → {'.'.join(map(str, new_ver))}")
        return

    print("\nBumping chart versions:")
    if repo_scopes:
        print(f"  Repo-level changes: {chart_bumps[DEFAULT_SCOPE]} (no single chart affected)")

    for chart in sorted(chart_scopes):
        ver = get_current_version(chart)
        new_ver = bump_version(ver, chart_bumps[chart])
        write_version(chart, new_ver)
        run_git("add", os.path.join(CHARTS_DIR, chart, "Chart.yaml"))


if __name__ == "__main__":
    main()
