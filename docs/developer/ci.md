<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# CI/CD

> **Note:** This document describes the upstream openDesk CI/CD process on GitLab. This GitHub fork uses GitHub Actions for linting, spell checking, and secret scanning. See `.github/workflows/` for the current CI configuration.

<!-- TOC -->
* [CI/CD](#cicd)
  * [Deployment](#deployment)
  * [Tests](#tests)
<!-- TOC -->

## Deployment

This repository uses GitHub Actions for continuous integration (see `.github/workflows/lint.yaml`). For production deployments, use helmfile directly:

```bash
helmfile -e default sync
```

## Tests

End-to-end testing is available via Bats. See [docs/testing.md](../testing.md) for details on running tests locally.
