#!/usr/bin/env bash
# Verify all Nix files in opendesk-nix have valid syntax

set -e

echo "=========================================="
echo "Nix Syntax Verification"
echo "=========================================="
echo

cd "$(dirname "$0")/.."

fail_count=0

echo "1. Testing library files..."
for f in lib/*.nix lib/*/*.nix; do
  if [ -f "$f" ]; then
    if nix-instantiate --parse-only "$f" > /dev/null 2>&1; then
      echo "  ✓ $(basename $f)"
    else
      echo "  ✗ $(basename $f)"
      fail_count=$((fail_count + 1))
    fi
  fi
done

echo
echo "2. Testing service files..."
service_count=0
for f in docker/services/*/nixos/default.nix; do
  service_count=$((service_count + 1))
  if ! nix-instantiate --parse-only "$f" > /dev/null 2>&1; then
    echo "  ✗ $(basename $(dirname $(dirname $f)))"
    fail_count=$((fail_count + 1))
  fi
done
if [ $service_count -gt 0 ]; then
  echo "  ✓ All $service_count service files parse correctly"
fi

echo
echo "3. Testing flake.nix..."
if nix-instantiate --parse-only flake.nix > /dev/null 2>&1; then
  echo "  ✓ flake.nix"
else
  echo "  ✗ flake.nix"
  fail_count=$((fail_count + 1))
fi

echo
echo "=========================================="
echo "Results: $(($service_count + $(find lib -name '*.nix' | wc -l) + 1)) files tested"
echo "Failures: $fail_count"
echo "=========================================="

if [ $fail_count -eq 0 ]; then
  echo "SUCCESS: All files have valid Nix syntax!"
  exit 0
else
  echo "FAILURE: $fail_count files have syntax errors"
  exit 1
fi
