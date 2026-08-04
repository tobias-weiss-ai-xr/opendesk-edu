#!/usr/bin/env bats
# =============================================================================
# Tests for opendesk-nix shell scripts
# Quality discipline ported from cibuilder-fork (stack4ops)
# =============================================================================

setup() {
    cd "$BATS_TEST_DIRNAME/.."
}

# =============================================================================
# push-to-opencode.sh
# =============================================================================

@test "push-to-opencode.sh exists and is executable" {
    [ -f "./push-to-opencode.sh" ]
    [ -x "./push-to-opencode.sh" ]
}

@test "push-to-opencode.sh has correct shebang" {
    run head -n 1 "./push-to-opencode.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "#!/bin/bash" ]]
}

@test "push-to-opencode.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" "./push-to-opencode.sh"
    [ "$status" -eq 0 ]
}

@test "push-to-opencode.sh has no bash syntax errors" {
    run bash -n "./push-to-opencode.sh"
    [ "$status" -eq 0 ]
}

@test "push-to-opencode.sh defines CORE_IMAGES" {
    run grep "CORE_IMAGES" "./push-to-opencode.sh"
    [ "$status" -eq 0 ]
}

@test "push-to-opencode.sh defines EDU_IMAGES" {
    run grep "EDU_IMAGES" "./push-to-opencode.sh"
    [ "$status" -eq 0 ]
}

@test "push-to-opencode.sh --help shows usage" {
    run ./push-to-opencode.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "push-to-opencode.sh --list without token still lists images" {
    run ./push-to-opencode.sh --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"ghcr.io"* ]]
}

@test "push-to-opencode.sh --dry-run without token is safe" {
    run ./push-to-opencode.sh --dry-run --core
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry-run"* ]]
    [[ "$output" != *"Pushing"* ]]
}

@test "push-to-opencode.sh rejects unknown options" {
    run ./push-to-opencode.sh --bogus-flag
    [ "$status" -ne 0 ]
}

@test "push-to-opencode.sh requires OPENCODE_TOKEN for real push" {
    unset OPENCODE_TOKEN
    run env -u OPENCODE_TOKEN ./push-to-opencode.sh --core
    # Either errors out (no token) or lists; must not silently push
    [[ "$output" != *"Pushing"* ]] || [[ "$output" == *"dry"* ]]
}

# =============================================================================
# toggle-image-source.sh
# =============================================================================

@test "toggle-image-source.sh exists and is executable" {
    [ -f "./toggle-image-source.sh" ]
    [ -x "./toggle-image-source.sh" ]
}

@test "toggle-image-source.sh has correct shebang" {
    run head -n 1 "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "#!/bin/bash" ]]
}

@test "toggle-image-source.sh uses set -euo pipefail" {
    run grep "set -euo pipefail" "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
}

@test "toggle-image-source.sh has no bash syntax errors" {
    run bash -n "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
}

@test "toggle-image-source.sh defines GHCR registry" {
    run grep 'GHCR_REGISTRY="ghcr.io"' "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
}

@test "toggle-image-source.sh defines opencode registry" {
    run grep 'OPENCODE_REGISTRY="registry.gitlab.opencode.de"' "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
}

@test "toggle-image-source.sh defines Zot registry" {
    run grep 'ZOT_REGISTRY="zot-registry.opendesk.svc:5000"' "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
}

@test "toggle-image-source.sh has IMAGE_MAP" {
    run grep "IMAGE_MAP" "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
}

@test "toggle-image-source.sh has IMAGE_TAGS" {
    run grep "IMAGE_TAGS" "./toggle-image-source.sh"
    [ "$status" -eq 0 ]
}

@test "toggle-image-source.sh status shows available sources" {
    run ./toggle-image-source.sh status
    [ "$status" -eq 0 ]
    [[ "$output" == *"ghcr"* ]]
    [[ "$output" == *"opencode"* ]]
    [[ "$output" == *"zot"* ]]
}

@test "toggle-image-source.sh rejects invalid source" {
    run ./toggle-image-source.sh bogus
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

# =============================================================================
# scripts/migrate-upstream-images.sh
# =============================================================================

@test "migrate-upstream-images.sh exists" {
    [ -f "./scripts/migrate-upstream-images.sh" ]
}

@test "migrate-upstream-images.sh has correct shebang" {
    run head -n 1 "./scripts/migrate-upstream-images.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "#!/usr/bin/env bash" ]]
}

@test "migrate-upstream-images.sh has no bash syntax errors" {
    run bash -n "./scripts/migrate-upstream-images.sh"
    [ "$status" -eq 0 ]
}

@test "migrate-upstream-images.sh documents --help" {
    run grep -- "--help" "./scripts/migrate-upstream-images.sh"
    [ "$status" -eq 0 ]
}

@test "migrate-upstream-images.sh uses set -uo pipefail or set -eu" {
    run grep -E "set -e?u?o? pipefail|set -uo pipefail|set -eu" "./scripts/migrate-upstream-images.sh"
    [ "$status" -eq 0 ]
}

# =============================================================================
# scripts/container-gov-de/*.sh
# =============================================================================

@test "container-gov-de scripts exist and are executable" {
    for f in check-compliance.sh build-all.sh push-all.sh sign-all.sh scan-all.sh generate-reports.sh deploy.sh; do
        [ -f "./scripts/container-gov-de/$f" ]
        [ -x "./scripts/container-gov-de/$f" ]
    done
}

@test "container-gov-de scripts have no bash syntax errors" {
    for f in ./scripts/container-gov-de/*.sh; do
        run bash -n "$f"
        [ "$status" -eq 0 ]
    done
}

@test "check-compliance.sh implements BG-1..BG-8" {
    for bg in BG-1 BG-2 BG-3 BG-4 BG-5 BG-6 BG-7 BG-8; do
        run grep -q "$bg" ./scripts/container-gov-de/check-compliance.sh
        [ "$status" -eq 0 ]
    done
}

# =============================================================================
# Makefile
# =============================================================================

@test "Makefile help target is not misspelled" {
    run grep "^help:" ./Makefile
    [ "$status" -eq 0 ]
}

@test "Makefile has validate-shell target" {
    run grep "^validate-shell:" ./Makefile
    [ "$status" -eq 0 ]
}

# =============================================================================
# Nix flake integrity
# =============================================================================

@test "flake.nix exists" {
    [ -f "./flake.nix" ]
}

@test "flake.nix has no obvious syntax errors (if nix available)" {
    if command -v nix >/dev/null 2>&1; then
        run nix-instantiate --parse ./flake.nix
        [ "$status" -eq 0 ]
    else
        skip "nix not installed"
    fi
}

@test "lib files exist for all modules" {
    for lib in types security sbom registry k8s build security-scanning cosign cicd dev tests; do
        [ -f "./lib/${lib}.nix" ]
    done
}

@test "compliance library implements BG-1..BG-8" {
    for bg in BG-1 BG-2 BG-3 BG-4 BG-5 BG-6 BG-7 BG-8; do
        run grep -q "$bg" ./lib/compliance/container-gov-de.nix
        [ "$status" -eq 0 ]
    done
}

@test "no literal brace-expansion directories remain" {
    run bash -c "find . -maxdepth 4 \( -name '*,*' -o -name '{*}' \) -not -path './.git/*' 2>/dev/null"
    [ -z "$output" ]
}
