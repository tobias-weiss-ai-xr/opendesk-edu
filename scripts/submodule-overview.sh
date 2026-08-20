#!/bin/bash
# SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
#
# Submodule Overview Script for opendesk_git
# Shows status, branch, commit, and remote URL for all submodules

echo "================================================================================"
echo "  OPENDESK GIT - SUBMODULE OVERVIEW"
echo "================================================================================="
echo ""
echo "Generated: $(date)"
echo ""

# Counters
total=0
up_to_date=0
ahead=0
behind=0
modified=0
uninitialized=0

# Parse git submodule status
echo "+----------------+----------------------------------+----------------------------------------+--------------------------+-------------------+"
echo "| STATUS         | SUBMODULE                      | BRANCH                                 | COMMIT                   | SOURCE            |"
echo "+----------------+----------------------------------+----------------------------------------+--------------------------+-------------------+"

git submodule status | while read -r hash path branch_etc; do
    total=$((total + 1))
    
    # Extract branch info
    branch_info="${branch_etc# )}"
    
    # Determine status
    if [[ "$hash" == "-" ]]; then
        status="NOT INIT"
        uninitialized=$((uninitialized + 1))
    elif [[ "$branch_etc" == *"+"* ]]; then
        status="AHEAD"
        ahead=$((ahead + 1))
    elif [[ "$branch_etc" == *“-”* ]]; then
        status="BEHIND"
        behind=$((behind + 1))
    elif [[ "$hash" == "+" ]]; then
        status="NEW COMMITS"
        modified=$((modified + 1))
    else
        status="OK"
        up_to_date=$((up_to_date + 1))
    fi
    
    # Get the remote URL and simplify
    url=$(git config --file .git/config submodule.$path.url 2>/dev/null)
    if [[ "$url" == git@gitlab.hrz.uni-marburg.de:* ]]; then
        source="HRZ GitLab"
    elif [[ "$url" == git@github.com:tobias-weiss-ai-xr/* ]]; then
        source="GitHub (t-ai-xr)"
    elif [[ "$url" == git@github.com:opendesk-edu/* ]]; then
        source="GitHub (edu)"
    elif [[ "$url" == https://gitlab.opencode.de/* ]]; then
        source="OpenCode.de"
    elif [[ "$url" == git@codeberg.org:* ]]; then
        source="Codeberg"
    else
        source="External"
    fi
    
    # Get short hash
    short_hash="${hash:0:8}"
    
    # Format output
    printf "| %-14s | %-32s | %-38s | %-24s | %-17s |\n" \
        "$status" "$path" "$branch_info" "$short_hash" "$source"
done

echo "+----------------+----------------------------------+----------------------------------------+--------------------------+-------------------+"
echo ""
echo "Summary:"
echo "  Total submodules:     $total"
echo "  Up to date:           $up_to_date"
echo "  New commits:          $modified"
echo "  Ahead:               $ahead"
echo "  Behind:              $behind"
echo "  Not initialized:      $uninitialized"
echo ""

# Group by source

echo "================================================================================"
echo "  GROUPED BY SOURCE"
echo "================================================================================="
echo ""

echo "HRZ GitLab (Internal Deployment):"
echo "  ------------------------------------"
git submodule status | while read -r hash path branch_etc; do
    url=$(git config --file .git/config submodule.$path.url 2>/dev/null)
    if [[ "$url" == git@gitlab.hrz.uni-marburg.de:* ]]; then
        branch_info="${branch_etc# )}"
        short_hash="${hash:0:8}"
        printf "  * %-30s %-10s %s\n" "$path" "$short_hash" "$branch_info"
    fi
done
echo ""

echo "GitHub (tobias-weiss-ai-xr - Source of Truth):"
echo "  -----------------------------------------------"
git submodule status | while read -r hash path branch_etc; do
    url=$(git config --file .git/config submodule.$path.url 2>/dev/null)
    if [[ "$url" == git@github.com:tobias-weiss-ai-xr/* ]]; then
        branch_info="${branch_etc# )}"
        short_hash="${hash:0:8}"
        printf "  * %-30s %-10s %s\n" "$path" "$short_hash" "$branch_info"
    fi
done
echo ""

echo "GitHub (opendesk-edu organization):"
echo "  -------------------------------------"
git submodule status | while read -r hash path branch_etc; do
    url=$(git config --file .git/config submodule.$path.url 2>/dev/null)
    if [[ "$url" == git@github.com:opendesk-edu/* ]]; then
        branch_info="${branch_etc# )}"
        short_hash="${hash:0:8}"
        printf "  * %-30s %-10s %s\n" "$path" "$short_hash" "$branch_info"
    fi
done
echo ""

echo "External Upstream:"
echo "  ------------------"
git submodule status | while read -r hash path branch_etc; do
    url=$(git config --file .git/config submodule.$path.url 2>/dev/null)
    if [[ "$url" != git@gitlab.hrz.uni-marburg.de:* ]] && [[ "$url" != git@github.com:tobias-weiss-ai-xr/* ]] && [[ "$url" != git@github.com:opendesk-edu/* ]]; then
        branch_info="${branch_etc# )}"
        short_hash="${hash:0:8}"
        printf "  * %-30s %-10s %s\n" "$path" "$short_hash" "$branch_info"
    fi
done
echo ""

echo "================================================================================"
echo "  QUICK COMMANDS"
echo "================================================================================="
echo ""
echo "  Update all submodules to current commit:"
echo "    git submodule update --init --recursive"
echo ""
echo "  Update to latest remote (respects .gitmodules URLs):"
echo "    git submodule update --remote --recursive"
echo ""
echo "  Update all submodules and checkout their default branches:"
echo "    git submodule update --remote --recursive --checkout"
echo ""
echo "  Check status of all submodules:"
echo "    git submodule status"
echo ""
echo "  Clone this repo with all submodules:"
echo "    git clone --recurse-submodules <repo-url>"
echo ""
echo "  Pull latest changes including submodules:"
echo "    git pull"
echo "    git submodule update --recursive"
echo ""
