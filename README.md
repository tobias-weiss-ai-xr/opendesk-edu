<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>openDesk Deployment Automation</h1>

<!-- TOC -->
* [Overview](#overview)
* [Disclaimer](#disclaimer)
* [Requirements](#requirements)
* [Getting started](#getting-started)
* [Advanced customization](#advanced-customization)
* [Releases](#releases)
* [Components](#components)
* [Feedback](#feedback)
* [License](#license)
* [Copyright](#copyright)
<!-- TOC -->

# Overview

openDesk is a Kubernetes based, open-source and cloud-native digital workplace suite provided by the "Projektgruppe für
Aufbau ZenDiS" of Germany's Federal Ministry of the Interior.

openDesk currently features the following functional main components:

| Function             | Functional Component        | Component<br/>Version | Upstream Documentation |
| -------------------- | --------------------------- | --------------------- | ----------------- |
| Chat & collaboration | Element ft. Nordeck widgets | [1.11.52](https://github.com/element-hq/element-desktop/blob/develop/CHANGELOG.md#changes-in-11152-2023-12-19) | [For the most recent release](https://element.io/user-guide) |
| Diagram editor       | Cryptpad ft. diagrams.net   | [5.6.0](https://github.com/cryptpad/cryptpad/releases/tag/5.6.0) | [For the most recent release](https://docs.cryptpad.org/en/) |
| File management      | Nextcloud                   | [28.0.2](https://nextcloud.com/de/changelog/#28-0-2) | [Nextcloud 28](https://docs.nextcloud.com/) |
| Groupware            | OX Appsuite                 | [8.20](https://documentation.open-xchange.com/appsuite/releases/8.20/) | Online documentation available from within the installed application; [Additional resources](https://www.open-xchange.com/resources/oxpedia) |
| Knowledge management | XWiki                       | [15.10.4](https://www.xwiki.org/xwiki/bin/view/Blog/XWiki15104Released) | [For the most recent release](https://www.xwiki.org/xwiki/bin/view/Documentation) |
| Portal & IAM         | Nubus                       | Product Preview[^1]   | [Univention's documentation website](https://docs.software-univention.de/n/en/index.html) |
| Project management   | OpenProject                 | [13.2.1](https://www.openproject.org/docs/release-notes/13-2-1/) | [For the most recent release](https://www.openproject.org/docs/user-guide/) |
| Videoconferencing    | Jitsi                       | [2.0.8922](https://github.com/jitsi/jitsi-meet/releases/tag/stable%2Fjitsi-meet_8922) | [For the most recent  release](https://jitsi.github.io/handbook/docs/category/user-guide/) |
| Weboffice            | Collabora                   | [23.05.8.4.1](https://www.collaboraoffice.com/collabora-online-23-05-release-notes/) | Online documentation available from within the installed application; [Additional resources](https://sdk.collaboraonline.com/) |

While not all components are perfectly shaped for the execution inside containers, one of the project's objectives is to
align the applications with best practises regarding container design and operations.

This documentation aims to give you all that is needed to set up your own instance of the openDesk.

Basic knowledge of Kubernetes and DevOps processes is required though.

# Disclaimer

openDesk will face breaking changes in the near future without upgrade paths before
[technical release](https://gitlab.opencode.de/bmi/opendesk/deployment/sovereign-workplace/-/releases)
v1.0.0 is reached.

While most components support upgrades, major configuration or component changes may occur, therefore we recommend
from scratch installations for now.

In the next months, we not only expect to integrate upstream updates of the functional components to include their
most recent feature and security sets, but also to address operational topics like scalability for the openDesk
platform.

Of course, further development also includes enhancing the documentation itself.

# Requirements

⟶ Visit our detailed [Requirements](./docs/requirements.md) overview.

# Getting started

⟶ Visit our detailed [Getting started](./docs/getting-started.md) guide.

# Advanced customization

- [External services](./docs/external-services.md)
- [Security](./docs/security.md)
- [Scaling](./docs/scaling.md)
- [Monitoring](./docs/monitoring.md)
- [Theming](./docs/theming.md)

# Releases

All technical releases are created using [Semantic Versioning](https://semver.org/lang/de/).

Gitlab provides an
[overview on the releases](https://gitlab.opencode.de/bmi/opendesk/deployment/sovereign-workplace/-/releases)
of this project.

The following release artefacts are provided beside the default source code assets:
- `chart-index.json`: An overview of all Helm charts used by the release.
- `image-index.json`: An overview of all container images used by the release.

⟶ Visit our detailed [Workflow](./docs/workflow.md) docs.

# Components

⟶ Visit our detailed [Component](./docs/components.md) docs.

# Feedback

We love to get feedback from you!

Related to the deployment / contents of this repository,
please use the [issues within this project](https://gitlab.opencode.de/bmi/opendesk/deployment/sovereign-workplace/-/issues).

If you want to address other topics, please check the section
["Rückmeldungen und Beteiligung" of the Infos' project OVERVIEW.md](https://gitlab.opencode.de/bmi/opendesk/info/-/blob/main/OVERVIEW.md#rückmeldungen-und-beteiligung).

# License

This project uses the following license: Apache-2.0

# Copyright

Copyright (C) 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
