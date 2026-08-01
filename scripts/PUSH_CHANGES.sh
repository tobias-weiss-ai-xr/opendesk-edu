#!/bin/bash

# PUSH_CHANGES.sh - Script to push all ZKI implementation changes
# Usage: ./PUSH_CHANGES.sh [branch] [remote]

# SPDX-FileCopyrightText: 2026 openDesk Contributors
# SPDX-License-Identifier: Apache-2.0

set -e

echo "=========================================="
echo "Pushing ZKI Implementation Changes"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    echo "   Please cd to /home/weissto_local/git/opendesk_git/"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  You have uncommitted changes:"
    git status --short
    read -p "   Would you like to commit them first? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        git commit -m "feat: Commit uncommitted changes before push"
    fi
fi

# Determine branch
BRANCH=${1:-master}
echo "📝 Using branch: $BRANCH"

# Determine remote
REMOTE=${2:-origin}
echo "🌍 Using remote: $REMOTE"

# Check if remote exists
if ! git remote | grep -q "$REMOTE"; then
    echo "❌ Remote '$REMOTE' does not exist"
    read -p "   Would you like to add it? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "   Enter remote URL: " REMOTE_URL
        git remote add $REMOTE $REMOTE_URL
    else
        echo "   Please add remote manually first:"
        echo "   git remote add $REMOTE <url>"
        exit 1
    fi
fi

# Show what we're about to push
echo ""
echo "📊 Changes to be pushed:"
echo "----------------------------------------"
git show --stat --no-patch HEAD
echo "----------------------------------------"
echo ""

# Push changes
echo "🚀 Pushing to $REMOTE/$BRANCH..."
git push -u $REMOTE $BRANCH

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to $REMOTE/$BRANCH"
    echo ""
    echo "📋 Summary of pushed changes:"
    echo "   - Added 10 new ZKI implementation files"
    echo "   - Total: ~295 KB, ~10,300 lines of comprehensive analysis"
    echo "   - Files: START_HERE.md, INDEX_ALL_ZKI_FILES.md, VISUAL_SUMMARY.md,"
    echo "            DASHBOARD.md, QUICK_REFERENCE.md, COMPREHENSIVE_GAP_ANALYSIS.md,"
    echo "            COMPREHENSIVE_GAP_ANALYSIS_PART2.md, ACTION_PLAN_COMPLETE.md,"
    echo "            COMPREHENSIVE_ANALYSIS_SUMMARY.md, ZKI_CRITICAL_ACTIONS.md"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Read START_HERE.md to understand the implementation"
    echo "   2. Read ZKI_CRITICAL_ACTIONS.md to see what blocks production"
    echo "   3. Start working on your assigned P0 actions"
else
    echo ""
    echo "❌ Failed to push changes"
    echo "   Please check your git configuration and try again"
    exit 1
fi

echo ""
echo "=========================================="
echo "Push Complete!"
echo "=========================================="
