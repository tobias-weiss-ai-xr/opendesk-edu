<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# 🤖 Continuous Self-Improvement Agent

An automated agent that continuously monitors, analyzes, and improves the openDesk Edu OpenSpec documentation. Runs as a GitLab CI scheduled pipeline.

## Overview

The Self-Improvement Agent performs continuous quality assurance on the OpenSpec by:

1. **Auditing** all OpenSpec files for completeness and consistency
2. **Detecting** gaps, missing sections, and improvement opportunities
3. **Generating** automated fixes for common issues
4. **Creating** merge requests with proposed improvements
5. **Reporting** coverage statistics and quality metrics

## Features

- ✅ **Comprehensive auditing** - Checks for required sections (Purpose, Scope, SLO, DR, etc.)
- 🔍 **Consistency validation** - Detects broken cross-references and inconsistencies
- 🤖 **Automated fixes** - Auto-fixes simple issues like missing `## Scope` sections
- 📊 **Coverage statistics** - Tracks documentation completeness over time
- 🔄 **GitLab integration** - Creates merge requests automatically
- 📅 **Scheduled execution** - Runs weekly via GitLab scheduled pipelines
- 📈 **Trend analysis** - Historical reports show improvement progress

## Architecture

```
┌─────────────────────┐
│  GitLab CI Pipeline │
│  (Scheduled/Manual) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Audit Stage        │
│  - Scan specs       │
│  - Detect gaps      │
│  - Generate report  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Improve Stage      │
│  - Apply fixes      │
│  - Create branch    │
│  - Commit changes   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Report Stage       │
│  - Generate MR      │
│  - Markdown report  │
│  - Publish metrics  │
└─────────────────────┘
```

## Usage

### Running Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run audit (read-only)
python improvement_agent.py

# Run with auto-fix and MR creation
CREATE_MERGE_REQUEST=true python improvement_agent.py

# Generate markdown report
python generate_report.py improvement-report.json
```

### Running in GitLab CI

The pipeline is automatically triggered by:

1. **Scheduled runs** (weekly recommended) - Configured in GitLab CI/CD schedules
2. **Manual trigger** - Via GitLab UI "Run pipeline" button
3. **Merge requests** - Validates changes to `openspec/specs/**/spec.md`
4. **Push events** - When service specs are modified

### Setting Up Scheduled Pipeline

1. Go to **CI/CD → Schedules** in your GitLab project
2. Create a new schedule:
   - **Description**: "Weekly OpenSpec audit"
   - **Interval pattern**: `0 2 * * 1` (every Monday at 2 AM)
   - **Target branch**: `main`
3. Save and enable the schedule

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `IMPROVEMENT_REPORT_FILE` | `improvement-report.json` | Output report file path |
| `CREATE_MERGE_REQUEST` | `false` | Set to `true` to create MRs automatically |
| `REPO_ROOT` | `.` | Repository root directory |
| `GITLAB_TOKEN` | - | GitLab API token for MR creation |
| `CI_PROJECT_ID` | - | GitLab project ID |

### Required Sections

The agent checks for these required sections in service specs:

- `## Purpose` - Service purpose and overview
- `## Scope` - Feature boundaries and exclusions
- `## Non-Goals` - Explicit non-goals
- `## Requirements` - Functional requirements
- `## Depends On` - Dependencies
- `## SLO` - Service Level Objectives
- `## Disaster Recovery` - DR procedures

## Output

### JSON Report

```json
{
  "timestamp": "2026-06-27T12:00:00Z",
  "total_gaps": 42,
  "critical_gaps": 5,
  "high_gaps": 12,
  "medium_gaps": 20,
  "low_gaps": 5,
  "auto_fixable": 3,
  "coverage_stats": {
    "services": {
      "total": 25,
      "with_scope": 25,
      "with_depends_on": 25,
      "with_slo": 25,
      "with_dr": 25
    }
  },
  "gaps": [...]
}
```

### Markdown Report

The agent also generates a human-readable markdown report with:
- Executive summary
- Coverage statistics
- Detailed gap analysis
- Recommendations

### Merge Request

When improvements are detected, the agent creates a merge request:

**Title**: `🤖 Self-Improvement: N automated fixes`

**Description**: Includes audit results, changes applied, and review checklist.

## Examples

### Detecting Missing Scope Section

```python
# Agent detects:
{
  "category": "missing_section",
  "severity": "critical",
  "service": "new-service",
  "file_path": "openspec/specs/services/new-service/spec.md",
  "description": "Missing required section: ## Scope",
  "auto_fixable": true,
  "fix_patch": "## Scope\n\nThis spec defines:\n- ✅ In scope: [...]\n- ❌ Out of scope: [...]"
}
```

### Detecting Broken References

```python
# Agent detects:
{
  "category": "broken_reference",
  "severity": "low",
  "service": "nextcloud",
  "file_path": "openspec/specs/services/nextcloud/spec.md",
  "description": "Broken cross-reference: ../nonexistent/spec.md"
}
```

## Security Considerations

- **GitLab token** must have `api` scope for MR creation
- **Branch protection** rules should require review before merging auto-generated MRs
- **Rate limiting** prevents excessive API calls
- **Dry-run mode** available for testing without changes

## Future Enhancements

- [ ] **AI-powered suggestions** - Use LLM to generate more sophisticated improvements
- [ ] **Trend analysis** - Track coverage statistics over time
- [ ] **Slack/email notifications** - Alert team about new gaps
- [ ] **Custom rules** - Allow project-specific gap definitions
- [ ] **Integration tests** - Verify improvements don't break existing docs
- [ ] **Performance metrics** - Track audit execution time

## Contributing

To add new audit rules:

1. Edit `improvement_agent.py`
2. Add new gap detection logic in `OpenSpecAuditor`
3. Update `REQUIRED_SECTIONS` or add custom checks
4. Test locally before committing

## License

Apache-2.0

---

🤖 **Powered by openDesk Edu Continuous Self-Improvement Agent**
