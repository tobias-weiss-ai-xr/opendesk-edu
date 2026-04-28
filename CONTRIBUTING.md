<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# How to contribute

While openDesk integrates community and supplier artifacts that follow their own contribution processes, you can contribute to openDesk "owned" components via openCode. These components are organized across several areas within the [base group](https://gitlab.opencode.de/bmi/opendesk):

- [Deployment](https://gitlab.opencode.de/bmi/opendesk/deployment), including the [openDesk main repository](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk)
- [Tooling](https://gitlab.opencode.de/bmi/opendesk/tooling)
- [Documentation](https://gitlab.opencode.de/bmi/opendesk/documentation)
- [Container images](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images)
- [Helm charts](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts)

For full details on the contribution process, please refer to the [README.md of the project dedicated to contributions](https://gitlab.opencode.de/bmi/opendesk/contributing/cla-signer/-/blob/main/README.md).

The main repository in particular provides detailed guidelines, outlined in the sections below.

## Standards and conventions

Please review the [project's workflow documentation](./docs/developer/workflow.md) for further details on standards such as commit message formatting and branching conventions.

## Helm vs. Operators vs. Manifests

To align with the [Deutsche Verwaltungscloud-Strategie (DVS)](https://www.cio.bund.de/Webs/CIO/DE/digitale-loesungen/digitale-souveraenitaet/deutsche-verwaltungscloud-strategie/deutsche-verwaltungscloud-strategie-node.html) and the
expectations of DVC platform operators, openDesk follows these packaging
conventions:

- We package components as [Helm charts](https://helm.sh/) (which may bundle Manifests).
- We avoid stand-alone Manifests where a Helm chart is more appropriate.
- We avoid Kubernetes Operators and Custom Resource Definitions (CRDs).

The DVS does not formally prohibit Operators or CRDs, but the relevant
specifications strongly favor portable, self-contained delivery artifacts
that any DVC platform operator can deploy without granting cluster-scoped
permissions or extending the Kubernetes API. In particular:

- [DVC Detailstandard 41 — Vorgaben für die Lieferung oder Bereitstellung von containerisierten Softwareprodukten](https://docs.fitko.de/dvc-standards/docs/detailstandard_41/) defines containerized software delivery via OCI-compliant registries and Helm-based packaging.
- [DVC Detailstandard 16 — Deployment von Softwarelösungen](https://docs.fitko.de/dvc/docs/detailstandards/detailstandard_16/) places responsibility for deployment on the software operator (Softwarebetreiber), who must comply with the platform operator's regulatory and BSI IT-Grundschutz requirements - constraints that are difficult to honor when applications introduce their own CRDs and cluster-wide controllers.
- The [Rahmenwerk zur Zielarchitektur der DVS](https://www.cio.bund.de/SharedDocs/downloads/Webs/CIO/DE/cio-bund/steuerung-it-bund/beschluesse_cio-board/2022_01_Beschluss_CIO_Board_Anlage_DVS_Rahmenwerk.pdf) establishes the overarching principles of modularity, interoperability, and vendor-independent standards that motivate this approach.

Avoiding Operators and CRDs keeps openDesk deployable on any compliant DVC platform with namespace-scoped permissions, simplifies certification, and reduces the operational surface that platform operators have to support.

To unify the Helm files from the various openDesk components into a single
deployment, we use [Helmfile](https://github.com/helmfile/helmfile).

## Tooling

New tools should not be introduced without prior discussion with the team. Proposals are welcome, but the team must decide whether a tool will be adopted.

Please help us avoid unnecessary complexity.

## In doubt? Open an issue!

We always welcome contributions. To avoid wasted effort, especially on larger changes, we encourage you to [open an issue](https://gitlab.opencode.de/bmi/opendesk/deployment/sovereign-workplace/-/issues/new) to discuss your idea and proposed approach beforehand. This is the best way to align your contribution with ongoing work, the overall openDesk platform strategy, and any prior considerations the team may have on the topic.