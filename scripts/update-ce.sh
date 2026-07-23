#!/bin/bash
# update-ce.sh — Update openDesk CE submodule to latest version
# Usage: ./scripts/update-ce.sh [version]
#   version: Git tag or branch (default: check upstream remote for latest tag)
#
# This updates helmfile/ce/ to the specified version and commits the change.
# After updating, verify with:
#   git diff --submodule    # shows which CE commits changed
#   git log --oneline -1   # confirms the submodule pointer

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CE_DIR="$REPO_DIR/helmfile/ce"

cd "$CE_DIR"

# Ensure upstream remote exists
if ! git remote get-url upstream &>/dev/null; then
  echo "Adding upstream remote..."
  git remote add upstream https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk.git
fi

# Fetch upstream tags
echo "Fetching upstream tags..."
git fetch upstream --tags --force

# Determine target version
if [ $# -ge 1 ]; then
  VERSION="$1"
else
  VERSION="$(git tag -l 'v*' --sort=-v:refname | head -1)"
  echo "No version specified. Using latest: $VERSION"
fi

if [ -z "$VERSION" ]; then
  echo "ERROR: Could not determine version. Specify as argument."
  exit 1
fi

echo "Updating CE submodule to $VERSION..."
git checkout "$VERSION"

cd "$REPO_DIR"

echo "Staging submodule change..."
git add helmfile/ce

echo "Ready to commit. Run:"
echo "  git commit -m \"chore: bump CE submodule to $VERSION\""
echo ""
echo "Verify the changes:"
echo "  git diff --submodule"
echo "  git log --oneline helmfile/ce"
