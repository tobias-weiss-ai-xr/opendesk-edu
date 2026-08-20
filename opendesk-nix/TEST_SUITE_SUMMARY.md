# Test Suite Summary — opendesk-nix

> Quality discipline ported from **cibuilder-fork** (stack4ops),
> which standardized 283 Bats tests across its CI build environment.

## Overview

| Suite | File | Tests | Coverage |
|-------|------|-------|----------|
| Shell Scripts | `tests/scripts.bats` | 37 | push-to-opencode.sh, toggle-image-source.sh, migrate-upstream-images.sh, container-gov-de scripts |

## Usage

```bash
# Run all tests
make test

# Verbose output
make test-verbose

# Test statistics
make test-count

# Shell linting
make shellcheck
```

## Coverage Areas

### push-to-opencode.sh
- Script structure (shebang, `set -euo pipefail`, executable)
- Image list definitions (CORE_IMAGES, EDU_IMAGES)
- `--help`, `--list`, `--dry-run` safe behavior without token
- Token requirement for real pushes
- Unknown option rejection

### toggle-image-source.sh
- Script structure and registry mapping definitions
- GHCR / opencode.de / Zot registry constants
- `status` subcommand output
- Invalid source rejection

### migrate-upstream-images.sh
- Script structure and `--help` documentation
- Syntax validation

### container.gov.de compliance
- All 8 BG-1..BG-8 checks present in `check-compliance.sh`
- All 7 scripts exist and are executable
- Bash syntax validation for all scripts

### Nix integrity
- `flake.nix` parse check (when nix available)
- All 11 lib modules present
- Compliance library BG-1..BG-8 coverage
- No literal brace-expansion directories

## CI Integration

GitLab CI (`test:scripts` job) runs the suite using `bats/bats:latest`.
