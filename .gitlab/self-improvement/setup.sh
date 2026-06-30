#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
# Setup script for the self-improvement agent
#
# This script:
# 1. Verifies Python dependencies
# 2. Sets up the scheduled pipeline in GitLab
# 3. Creates necessary CI/CD variables
# 4. Tests the agent locally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=================================================="
echo "openDesk Edu Self-Improvement Agent Setup"
echo "=================================================="
echo ""

# Check Python version
echo "→ Checking Python version..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.11+"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "✅ Python ${PYTHON_VERSION} found"

# Install dependencies
echo ""
echo "→ Installing Python dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install -q -r "${SCRIPT_DIR}/requirements.txt"
    echo "✅ Dependencies installed"
else
    echo "⚠️  pip3 not found, skipping dependency installation"
    echo "   Install manually with: pip3 install -r ${SCRIPT_DIR}/requirements.txt"
fi

# Test the agent
echo ""
echo "→ Testing the agent..."
if python3 "${SCRIPT_DIR}/improvement_agent.py" > /dev/null 2>&1; then
    echo "✅ Agent test successful"
else
    echo "❌ Agent test failed"
    exit 1
fi

# Check GitLab CLI
echo ""
echo "→ Checking GitLab CLI..."
if command -v glab &> /dev/null; then
    echo "✅ GitLab CLI found"

    # Check if we're in a GitLab repo
    if git remote get-url origin 2>/dev/null | grep -q "gitlab.com\|gitlab.opencode.de"; then
        echo "✅ GitLab repository detected"

        # Create CI/CD variables if token is available
        if [ -n "${GITLAB_TOKEN:-}" ]; then
            echo ""
            echo "→ Setting up CI/CD variables..."
            echo "   (This requires GITLAB_TOKEN with api scope)"

            glab variable set GITLAB_TOKEN --value "${GITLAB_TOKEN}" --masked --protected 2>/dev/null || echo "   ⚠️  Could not set GITLAB_TOKEN"
            echo "   ✅ Variables configured"
        else
            echo "   ⚠️  GITLAB_TOKEN not set, skipping variable creation"
            echo "   Set with: export GITLAB_TOKEN=your_token"
        fi

        # Create scheduled pipeline
        echo ""
        echo "→ Creating scheduled pipeline..."
        echo "   (You can also do this manually in GitLab UI: CI/CD → Schedules)"

        cat <<EOF

   Recommended schedule:
   - Description: Weekly OpenSpec audit
   - Interval: 0 2 * * 1 (every Monday at 2 AM)
   - Target branch: main
   - Variables: CREATE_MERGE_REQUEST=true

EOF
    else
        echo "⚠️  Not a GitLab repository, skipping GitLab-specific setup"
    fi
else
    echo "⚠️  GitLab CLI (glab) not found"
    echo "   Install from: https://gitlab.com/gitlab-org/cli"
    echo "   Or set up the scheduled pipeline manually in GitLab UI"
fi

echo ""
echo "=================================================="
echo "✅ Setup complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Review the generated improvement-report.json"
echo "2. Commit the .gitlab/self-improvement/ directory"
echo "3. Set up a scheduled pipeline in GitLab (CI/CD → Schedules)"
echo "4. Trigger a manual run to test the pipeline"
echo ""
echo "For more information, see: ${SCRIPT_DIR}/README.md"
