<!--
SPDX-FileCopyrightText: 2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Release management</h1>

This document outlines the release and patch management strategy for **openDesk**, ensuring that all updates, patches, and new releases are systematically **planned, tested, documented**, and **reliably deployed** into production. The process is designed to align with operational planning requirements and maintain system stability and security.

<!-- TOC -->
* [Release cycle](#release-cycle)
  * [Release types](#release-types)
  * [Release schedule](#release-schedule)
  * [Upgrades](#upgrades)
* [Patch management process](#patch-management-process)
  * [Patch identification \& prioritization](#patch-identification--prioritization)
  * [Patch workflow](#patch-workflow)
* [Communication plan](#communication-plan)
  * [Announcement channels](#announcement-channels)
  * [Timing of communications](#timing-of-communications)
* [Documentation requirements](#documentation-requirements)
* [Compliance \& review](#compliance--review)
<!-- TOC -->

# Release cycle

openDesk follows a structured release cycle to ensure predictability and reliability:

## Release types

| Type           | Frequency     | Content                                                       |
|----------------|---------------|---------------------------------------------------------------|
| **Major**      | Annually (Q3) | Large feature sets, architecture changes, breaking changes |
| **Minor**      | Monthly        | New features, enhancements, may contain breaking changes or refactors (clearly flagged in the notes)              |
| **Patch**      | On demand      | Bug fixes, security updates, minor improvements, no intended breaking changes               |

> [!note]
> openDesk does **not** guarantee that minor releases are 100% backward‑compatible. When a breaking > change
> is unavoidable it is announced in the release notes under a dedicated header **“Breaking Changes”** > and a
> migration guide is provided.

## Release schedule

- **Major releases** are scheduled for **Q3 each year**, with planning beginning in Q1.
- **Minor releases** occur **monthly on Mondays**, typically **around 10:00 AM** local time.
  - Each minor release follows a **4-week cycle**.
  - **Week 1–3**: Active development of new features and improvements.
  - **End of Week 3**: **Feature freeze** is enforced to allow stabilization and testing.
  - **Week 4**: Final testing, approvals, and preparation for release.
  - At the **end of Week 4**, a new minor version is released, and a new cycle begins.
- **Patch releases** are created **on demand**, based on criticality and urgency.

## Upgrades

- openDesk does not guarantee an in‑place upgrade between two major versions. Always consult the release notes and plan appropriate migration efforts.
- Even within the same major line, skipping multiple monthly minor versions is not guaranteed to work without intermediate upgrade steps.
- All breaking changes, including those in monthly minor releases, are highlighted in the release notes under Breaking Changes.
- Additional, non‑binding migration hints are collected in [migrations.md](./migrations.md)

# Patch management process

A standardized process ensures patches are developed, prioritized, and deployed efficiently.

## Patch identification & prioritization

Patches are categorized by severity and urgency:

| Priority Level | Criteria                                                                 |
|----------------|--------------------------------------------------------------------------|
| **Critical**   | Security vulnerabilities, system outages, data loss risks                |
| **High**       | Major bugs affecting multiple users, performance degradation             |
| **Medium**     | Functional bugs with workarounds, minor usability issues                 |
| **Low**        | Cosmetic issues, documentation updates                                   |

## Patch workflow

The following steps define the patch workflow from issue identification to post-deployment review. This process ensures consistent quality and minimal disruption to users:

1. **Identification**: Potential issues are detected through automated monitoring, internal testing, audits, or user reports submitted via the support ticketing system.
2. **Assessment**: The product and engineering teams triage the issue, determine severity based on business and user impact, and prioritize it within the patch queue.
3. **Development**: A fix is implemented on a dedicated feature or hotfix branch, adhering to coding standards and version control protocols.
4. **Testing**: All patches undergo automated unit and integration tests, as well as manual QA validation in a staging environment that closely mirrors production.
5. **Approval**: Once tested, the patch must be approved by the product owner or a designated release manager, with proper documentation and change control entries.
6. **Deployment**: The patch is rolled out using CI/CD pipelines during predefined deployment windows or as soon as possible for critical issues.
7. **Post-deployment review**: After deployment, the fix is verified in production, and monitoring tools are used to detect regressions or unintended side effects.

This workflow ensures that patches are handled with the same level of discipline as planned releases, supporting both reliability and agility.

# Communication plan

A lightweight approach reduces manual effort while maintaining transparency.

## Announcement channels

| Channel | Audience | Purpose | Owner |
|---------|----------|---------|-------|
| **openCode Changelog** | Community & EE | Primary source of truth for every release | DevOps |
| **Account‑Manager Mail / Ticket** | Enterprise customers | Targeted information & upgrade advice | Customer Success |

## Timing of communications

| Release Type | What | When |
|--------------|------|------|
| **Major** | Roadmap entry + migration highlights | 4 weeks before release |
|            | Final confirmation | 1 week before release |
| **Minor** | Changelog entry (draft) | Immediately after feature freeze (end of week 3) |
|            | EE mail/ticket | 2 business days before deployment |
| **Patch** | Changelog entry | Right after production deploy |
|            | EE mail/ticket (only if impacted) | Within 1 business day |

Community users consume information via openCode; Enterprise customers get an additional nudge via their account manager – **no mass mailings are sent manually**.

# Documentation requirements

Each release (major, minor, or patch) must include:

- **Release notes** outlining new features, fixes, and known issues
- **Change logs** with commit references and affected components
- **Test reports** confirming QA coverage and results
- **Deployment checklist** reviewed and approved by the product owner

# Compliance & review

- The release process is reviewed **bi-annually** to incorporate feedback and evolving requirements
- Emergency patches (e.g., zero-day security issues) may bypass the standard schedule but must be documented post-deployment
