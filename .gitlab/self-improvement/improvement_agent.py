#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
"""
openDesk Edu Continuous Self-Improvement Agent

Analyzes the OpenSpec for gaps, inconsistencies, and improvement opportunities,
then automatically generates improvements and creates merge requests.

This agent is designed to run as a GitLab CI scheduled pipeline and can:
1. Audit OpenSpec documentation completeness
2. Detect missing or outdated sections
3. Identify inconsistencies across service specs
4. Generate improvement patches
5. Create merge requests automatically
"""

import os
import sys
import json
import yaml
import subprocess
import datetime
import logging
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict, field
from difflib import unified_diff

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('self-improvement-agent')


@dataclass
class Gap:
    """Represents a gap or improvement opportunity found in the OpenSpec."""
    category: str
    severity: str  # critical, high, medium, low
    service: str
    file_path: str
    description: str
    fix_suggestion: str
    auto_fixable: bool = False
    fix_patch: Optional[str] = None


@dataclass
class ImprovementReport:
    """Comprehensive report of improvements to be made."""
    timestamp: str
    total_gaps: int
    critical_gaps: int
    high_gaps: int
    medium_gaps: int
    low_gaps: int
    auto_fixable: int
    gaps: List[Dict] = field(default_factory=list)
    coverage_stats: Dict[str, Dict[str, int]] = field(default_factory=dict)


class OpenSpecAuditor:
    """Audits the openDesk Edu OpenSpec for completeness and consistency."""

    REQUIRED_SECTIONS = [
        '## Purpose',
        '## Scope',
        '## Non-Goals',
        '## Requirements',
        '## Depends On',
        '## SLO',
        '## Disaster Recovery',
    ]

    # Recommended (but not critical) sections
    OPTIONAL_SECTIONS = [
        '## Integrates With',
        '## Component Reference',
        '## Security Context',
        '## Configuration Reference',
    ]

    def __init__(self, openspec_root: str = 'openspec/specs'):
        self.openspec_root = Path(openspec_root)
        self.services_dir = self.openspec_root / 'services'
        self.platform_dir = self.openspec_root / 'platform'
        self.integrations_dir = self.openspec_root / 'integrations'

    def audit(self) -> ImprovementReport:
        """Run full audit and return improvement report."""
        logger.info("Starting OpenSpec audit...")

        gaps = []
        coverage_stats = {}

        # Audit service specs
        service_coverage = self._audit_services(gaps)

        # Audit platform specs
        platform_coverage = self._audit_platform_specs(gaps)

        # Audit integration specs
        integration_coverage = self._audit_integrations(gaps)

        # Audit consistency
        self._audit_consistency(gaps)

        # Generate report
        report = ImprovementReport(
            timestamp=datetime.datetime.utcnow().isoformat(),
            total_gaps=len(gaps),
            critical_gaps=sum(1 for g in gaps if g.severity == 'critical'),
            high_gaps=sum(1 for g in gaps if g.severity == 'high'),
            medium_gaps=sum(1 for g in gaps if g.severity == 'medium'),
            low_gaps=sum(1 for g in gaps if g.severity == 'low'),
            auto_fixable=sum(1 for g in gaps if g.auto_fixable),
            coverage_stats={
                'services': service_coverage,
                'platform': platform_coverage,
                'integrations': integration_coverage,
            }
        )

        for gap in gaps:
            report.gaps.append(asdict(gap))

        logger.info(f"Audit complete: {report.total_gaps} gaps found "
                    f"({report.critical_gaps} critical, {report.high_gaps} high)")
        return report

    def _audit_services(self, gaps: List[Gap]) -> Dict[str, int]:
        """Audit all service spec files."""
        coverage = {
            'total': 0,
            'with_scope': 0,
            'with_depends_on': 0,
            'with_slo': 0,
            'with_dr': 0,
        }

        if not self.services_dir.exists():
            logger.warning(f"Services directory not found: {self.services_dir}")
            return coverage

        for spec_file in self.services_dir.glob('*/spec.md'):
            coverage['total'] += 1
            service_name = spec_file.parent.name
            content = spec_file.read_text(encoding='utf-8')

            # Check required sections
            for section in self.REQUIRED_SECTIONS:
                if not self._has_section(content, section):
                    severity = 'critical' if section in ['## Scope', '## SLO', '## Disaster Recovery'] else 'high'
                    gap = Gap(
                        category='missing_section',
                        severity=severity,
                        service=service_name,
                        file_path=str(spec_file.relative_to('.')),
                        description=f"Missing required section: {section}",
                        fix_suggestion=f"Add {section} section to the spec",
                        auto_fixable=(section == '## Scope'),  # Only Scope is auto-fixable
                        fix_patch=self._generate_scope_template(service_name) if section == '## Scope' else None
                    )
                    gaps.append(gap)

            # Track coverage
            if self._has_section(content, '## Scope'):
                coverage['with_scope'] += 1
            if self._has_section(content, '## Depends On'):
                coverage['with_depends_on'] += 1
            if self._has_section(content, '## SLO'):
                coverage['with_slo'] += 1
            if self._has_section(content, '## Disaster Recovery'):
                coverage['with_dr'] += 1

        return coverage

    def _audit_platform_specs(self, gaps: List[Gap]) -> Dict[str, int]:
        """Audit platform-level specs."""
        coverage = {'total': 0}
        if not self.platform_dir.exists():
            return coverage

        for spec_file in self.platform_dir.rglob('spec.md'):
            coverage['total'] += 1
            content = spec_file.read_text(encoding='utf-8')

            if not self._has_section(content, '## Purpose'):
                gaps.append(Gap(
                    category='missing_section',
                    severity='high',
                    service='platform',
                    file_path=str(spec_file.relative_to('.')),
                    description="Platform spec missing ## Purpose section",
                    fix_suggestion="Add ## Purpose section",
                ))

        return coverage

    def _audit_integrations(self, gaps: List[Gap]) -> Dict[str, int]:
        """Audit integration specs."""
        coverage = {'total': 0}
        if not self.integrations_dir.exists():
            return coverage

        for spec_file in self.integrations_dir.rglob('spec.md'):
            coverage['total'] += 1
            content = spec_file.read_text(encoding='utf-8')

            if not self._has_section(content, '## Purpose'):
                gaps.append(Gap(
                    category='missing_section',
                    severity='medium',
                    service='integration',
                    file_path=str(spec_file.relative_to('.')),
                    description="Integration spec missing ## Purpose section",
                    fix_suggestion="Add ## Purpose section",
                ))

        return coverage

    def _audit_consistency(self, gaps: List[Gap]) -> None:
        """Check for consistency issues across specs."""
        # Check for consistent service naming
        service_names = set()
        for spec_file in self.services_dir.glob('*/spec.md'):
            service_names.add(spec_file.parent.name)

        # Check for orphaned cross-references
        for spec_file in self.services_dir.glob('*/spec.md'):
            content = spec_file.read_text(encoding='utf-8')
            # Find all markdown links to other services
            for match in re.finditer(r'\.\./([a-z-]+)/spec\.md', content):
                ref = match.group(1)
                if ref not in service_names and ref != '..':
                    gaps.append(Gap(
                        category='broken_reference',
                        severity='low',
                        service=spec_file.parent.name,
                        file_path=str(spec_file.relative_to('.')),
                        description=f"Broken cross-reference: ../{ref}/spec.md",
                        fix_suggestion=f"Either create {ref} spec or fix the reference",
                    ))

    def _has_section(self, content: str, section: str) -> bool:
        """Check if content has a specific section."""
        return bool(re.search(rf'^{re.escape(section)}\s*$', content, re.MULTILINE))

    def _generate_scope_template(self, service_name: str) -> str:
        """Generate a Scope section template for a service."""
        return f"""## Scope

This spec defines:
- ✅ **In scope**: [List features and responsibilities]
- ✅ **Out of scope**: [List exclusions and limitations]
"""


class ImprovementGenerator:
    """Generates improvement patches from gap analysis."""

    def __init__(self, report: ImprovementReport, repo_root: str = '.'):
        self.report = report
        self.repo_root = Path(repo_root)
        self.branch_name = f"self-improvement/{datetime.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"

    def generate_improvements(self) -> List[Tuple[Path, str, str]]:
        """Generate improvement patches. Returns list of (file_path, old_content, new_content)."""
        logger.info("Generating improvement patches...")
        improvements = []

        for gap_dict in self.report.gaps:
            if not gap_dict.get('auto_fixable'):
                continue

            gap = Gap(**gap_dict)
            file_path = self.repo_root / gap.file_path

            if not file_path.exists():
                logger.warning(f"File not found: {file_path}")
                continue

            old_content = file_path.read_text(encoding='utf-8')
            new_content = self._apply_fix(old_content, gap)

            if new_content != old_content:
                improvements.append((file_path, old_content, new_content))

        logger.info(f"Generated {len(improvements)} improvement patches")
        return improvements

    def _apply_fix(self, content: str, gap: Gap) -> str:
        """Apply a fix to the content based on the gap."""
        if gap.category == 'missing_section' and gap.fix_patch:
            # Insert the new section after ## Non-Goals
            return content.replace(
                '## Non-Goals',
                gap.fix_patch + '\n## Non-Goals',
                1
            )
        return content

    def create_branch_and_commit(self, improvements: List[Tuple[Path, str, str]]) -> bool:
        """Create a git branch, apply improvements, and commit."""
        if not improvements:
            logger.info("No improvements to apply")
            return False

        try:
            # Create branch
            subprocess.run(
                ['git', 'checkout', '-b', self.branch_name],
                cwd=self.repo_root,
                check=True,
                capture_output=True
            )
            logger.info(f"Created branch: {self.branch_name}")

            # Apply improvements
            for file_path, _, new_content in improvements:
                file_path.write_text(new_content, encoding='utf-8')
                logger.info(f"Updated: {file_path}")

            # Stage and commit
            subprocess.run(['git', 'add', '-A'], cwd=self.repo_root, check=True, capture_output=True)

            commit_message = self._generate_commit_message()
            subprocess.run(
                ['git', 'commit', '-m', commit_message],
                cwd=self.repo_root,
                check=True,
                capture_output=True
            )
            logger.info(f"Committed changes: {commit_message[:80]}...")

            # Push branch
            result = subprocess.run(
                ['git', 'push', '-u', 'origin', self.branch_name],
                cwd=self.repo_root,
                capture_output=True
            )

            if result.returncode == 0:
                logger.info(f"Pushed branch: {self.branch_name}")
                return True
            else:
                logger.warning(f"Could not push branch (this is OK for local-only runs): {result.stderr.decode()}")
                return True  # Branch still exists locally

        except subprocess.CalledProcessError as e:
            logger.error(f"Git operation failed: {e.stderr.decode() if e.stderr else str(e)}")
            return False

    def _generate_commit_message(self) -> str:
        """Generate a descriptive commit message."""
        return f"""chore(self-improvement): automated OpenSpec improvements

Automated improvements detected by the continuous self-improvement agent.

**Audit Results:**
- Total gaps: {self.report.total_gaps}
- Critical: {self.report.critical_gaps}
- High: {self.report.high_gaps}
- Medium: {self.report.medium_gaps}
- Auto-fixed: {self.report.auto_fixable}

**Coverage Statistics:**
{json.dumps(self.report.coverage_stats, indent=2)}

Generated by openDesk Edu Self-Improvement Agent
Timestamp: {self.report.timestamp}
"""


class GitLabIntegration:
    """Integrates with GitLab API to create merge requests."""

    def __init__(self, project_id: Optional[str] = None, gitlab_token: Optional[str] = None):
        self.project_id = project_id or os.environ.get('CI_PROJECT_ID')
        self.gitlab_token = gitlab_token or os.environ.get('GITLAB_TOKEN')
        self.api_url = os.environ.get('CI_API_V4_URL', 'https://gitlab.com/api/v4')

    def create_merge_request(self, source_branch: str, title: str, description: str) -> Optional[str]:
        """Create a merge request via GitLab API."""
        if not self.project_id or not self.gitlab_token:
            logger.warning("GitLab credentials not available, skipping MR creation")
            return None

        import urllib.request
        import urllib.parse
        import urllib.error

        url = f"{self.api_url}/projects/{self.project_id}/merge_requests"
        data = {
            'source_branch': source_branch,
            'target_branch': 'main',
            'title': title,
            'description': description,
            'remove_source_branch': 'true',
        }

        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(data).encode('utf-8'),
                headers={
                    'PRIVATE-TOKEN': self.gitlab_token,
                    'Content-Type': 'application/json',
                },
                method='POST'
            )
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                mr_url = result.get('web_url')
                logger.info(f"Created merge request: {mr_url}")
                return mr_url

        except urllib.error.HTTPError as e:
            logger.error(f"Failed to create MR: {e.code} {e.reason}")
            return None
        except Exception as e:
            logger.error(f"Error creating MR: {e}")
            return None


def main():
    """Main entry point for the self-improvement agent."""
    logger.info("=" * 70)
    logger.info("openDesk Edu Continuous Self-Improvement Agent")
    logger.info("=" * 70)

    # Parse arguments
    output_file = os.environ.get('IMPROVEMENT_REPORT_FILE', 'improvement-report.json')
    create_mr = os.environ.get('CREATE_MERGE_REQUEST', 'false').lower() == 'true'
    repo_root = os.environ.get('REPO_ROOT', '.')

    # Run audit
    auditor = OpenSpecAuditor(openspec_root=os.path.join(repo_root, 'openspec/specs'))
    report = auditor.audit()

    # Save report
    report_path = Path(output_file)
    report_path.write_text(json.dumps(asdict(report), indent=2, default=str))
    logger.info(f"Report saved to: {report_path}")

    # Print summary
    print("\n" + "=" * 70)
    print("AUDIT SUMMARY")
    print("=" * 70)
    print(f"Total gaps: {report.total_gaps}")
    print(f"  Critical: {report.critical_gaps}")
    print(f"  High:     {report.high_gaps}")
    print(f"  Medium:   {report.medium_gaps}")
    print(f"  Low:      {report.low_gaps}")
    print(f"Auto-fixable: {report.auto_fixable}")
    print("\nCoverage Statistics:")
    for category, stats in report.coverage_stats.items():
        print(f"  {category}: {stats}")
    print("=" * 70)

    # Generate improvements if any
    if report.auto_fixable > 0:
        logger.info(f"Found {report.auto_fixable} auto-fixable gaps")
        generator = ImprovementGenerator(report, repo_root=repo_root)
        improvements = generator.generate_improvements()

        if improvements:
            success = generator.create_branch_and_commit(improvements)
            if success and create_mr:
                gitlab = GitLabIntegration()
                mr_title = f"🤖 Self-Improvement: {report.auto_fixable} automated fixes"
                mr_description = f"""## Automated Self-Improvement

This merge request was automatically created by the openDesk Edu Continuous
Self-Improvement Agent running in GitLab CI.

### Audit Results
- **Total gaps detected**: {report.total_gaps}
- **Critical**: {report.critical_gaps}
- **High**: {report.high_gaps}
- **Medium**: {report.medium_gaps}
- **Auto-fixed**: {report.auto_fixable}

### Changes Applied
{len(improvements)} files updated with automated improvements.

### Review Checklist
- [ ] Review all auto-generated changes
- [ ] Verify section templates are appropriate
- [ ] Update any placeholders with service-specific content
- [ ] Ensure CI passes
- [ ] Merge if satisfied

---
🤖 Generated by openDesk Edu Self-Improvement Agent
Timestamp: {report.timestamp}
"""
                mr_url = gitlab.create_merge_request(generator.branch_name, mr_title, mr_description)
                if mr_url:
                    print(f"\n✅ Merge request created: {mr_url}")
                else:
                    print("\n⚠️  Could not create MR automatically (check GitLab credentials)")
    else:
        logger.info("No auto-fixable improvements found")

    # Exit with success if no critical gaps, or 1 if critical gaps remain
    sys.exit(0 if report.critical_gaps == 0 else 1)


if __name__ == '__main__':
    main()
