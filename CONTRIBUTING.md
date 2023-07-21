<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# Read me first

Please read the [project's overall CONTRIBUTING.md](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/info/-/blob/main/CONTRIBUTING.md) first.

# How to contribute?

When providing contributes to this project, please adhere to the standards and conventions described in further down in this document. Doing so please feel free to create merge requests.

# Standards and conventions

## Branching

We use of [Github flow](https://docs.github.com/en/get-started/quickstart/github-flow).

## Verified commits

We only allow verify commits:
- https://docs.gitlab.com/ee/user/project/repository/ssh_signed_commits/
- https://docs.gitlab.com/ee/user/project/repository/gpg_signed_commits/
- https://docs.gitlab.com/ee/user/project/repository/x509_signed_commits/

## Approval

MRs require one approval from the SouvAP devops team with security clearance.

## Conventional Commits

See https://www.conventionalcommits.org/en/v1.0.0/#summary for reference.

Commits that do not adhere to the standard might be rejected.

```text
<type>(<scope>): [path/to/issue#1] <short summary>
  │       │              │                │
  │       │              |                └─> Summary in present tense, sentence case, with no period at the end
  │       │              |
  │       │              └─> Issue reference (optional)
  │       │
  │       └─> Commit Scope: helmfile, docs, collabora, intercom-service, ...
  │
  └─> Commit Type: chore, ci, docs, feat, fix
```
Valid commit scopes:
- `helmfile`
- `ci`
- `docs`
- `collabora`
- `ìntercom-service`
- `jitsi`
- `keycloak`
- `keycloak-bootstrap`
- `nextcloud`
- `open-xchange`
- `openproject`
- `provisioning`
- `services`
- `univention-corporate-container`
- `xwiki`

## Semantic Release

See https://github.com/semantic-release/semantic-release for reference.

## Linting

Following linters must pass:
- [yaml-lint](https://github.com/adrienverge/yamllint)
- [helm-lint](https://helm.sh/docs/helm/helm_lint/)

## Helm vs. Operators vs. Manifests

Due to DVS requirements:

- we have to use [Helm charts](https://helm.sh/) (that can consist of Manifests).
- we should avoid stand alone Manifests.
- we do not use Operators and CRDs.

In order to align the Helm files from various sources into an unified deployment of the SWP we make use of to [Helmfile](https://github.com/helmfile/helmfile).

## Tooling

We should not introduce a new tool without sharing the purpose with the team and let the team decide if the tool should be used.

We should avoid adding unnecessary complexity.
