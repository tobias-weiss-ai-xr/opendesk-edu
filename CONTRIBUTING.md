<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# Read me first

Please read the [project's overall CONTRIBUTING.md](https://gitlab.opencode.de/bmi/opendesk/info/-/blob/main/CONTRIBUTING.md) first.

# How to contribute?

Please also read the [project's workflow documentation](./docs/workflow.md) for more details on standards like commit
messages and branching.

## Helm vs. Operators vs. Manifests

Due to DVS requirements:

- we have to use [Helm charts](https://helm.sh/) (that can consist of Manifests).
- we should avoid stand alone Manifests.
- we do not use Operators and CRDs.

In order to align the Helm files from various sources into the unified deployment of openDesk we make use of
[Helmfile](https://github.com/helmfile/helmfile).

## Tooling

We should not introduce a new tool without sharing the purpose with the team and let the team decide if the tool should
be used.

We should avoid adding unnecessary complexity.

## In doubt? Ask!

We are always happy about contributions, but also like to discuss technical approaches to solve a problem to ensure
a contribution fits the openDesk platform strategy or clarify that specific topics might be must ahead on our own
roadmap. So when in doubt please [open an issue](https://gitlab.opencode.de/bmi/opendesk/deployment/sovereign-workplace/-/issues/new) and start a discussion.
