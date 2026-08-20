#!/usr/bin/env bash
# passvault - Encrypted CLI password vault wrapper
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONPATH="$DIR" exec python3 -m passvault "$@"
