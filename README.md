<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>openDesk Deployment Automation</h1>

<!-- TOC -->
* [Overview](#overview)
* [Upgrades](#upgrades)
* [Requirements](#requirements)
* [Getting started](#getting-started)
* [Advanced customization](#advanced-customization)
* [Architecture](#architecture)
* [Testing](#testing)
* [Permissions](#permissions)
* [Releases](#releases)
* [Data storage](#data-storage)
* [Feedback](#feedback)
* [Development](#development)
* [License](#license)
* [Copyright](#copyright)
<!-- TOC -->

# Overview

openDesk is a Kubernetes-based, open-source and cloud-native digital workplace suite provided by the
*Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH*.

For production use, the [openDesk Enterprise Edition](./README-EE.md) is recommended.

openDesk currently features the following functional main components:

| Function             | Functional component        | License                                                                                | Component<br/>version                                                                         | Upstream documentation                                                                                                                |
|----------------------|-----------------------------|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| Chat & collaboration | Element ft. Nordeck widgets | AGPL-3.0-or-later (Element Web), AGPL-3.0-only (Synapse), Apache-2.0 (Nordeck widgets) | [1.12.6](https://github.com/element-hq/element-web/releases/tag/v1.12.6)                      | [For the most recent release](https://element.io/user-guide)                                                                          |
| Collaborative notes  | Notes (aka Docs)            | MIT                                                                                    | [4.4.0](https://github.com/suitenumerique/docs/releases/tag/v4.4.0)                           | Online documentation/welcome document available in installed application                                                              |
| Diagram editor       | CryptPad ft. diagrams.net   | AGPL-3.0-only                                                                          | [2025.9.0](https://github.com/cryptpad/cryptpad/releases/tag/2025.9.0)                        | [For the most recent release](https://docs.cryptpad.org/en/)                                                                          |
| File management      | Nextcloud                   | AGPL-3.0-or-later                                                                      | [31.0.7](https://nextcloud.com/de/changelog/#31-0-7)                                          | [Nextcloud 31](https://docs.nextcloud.com/)                                                                                           |
| Groupware            | OX App Suite                | GPL-2.0-only (backend), AGPL-3.0-or-later (frontend)                                   | [8.44](https://documentation.open-xchange.com/appsuite/releases/8.44/)                        | Online documentation available from within the installed application; [Additional resources](https://documentation.open-xchange.com/) |
| Knowledge management | XWiki                       | LGPL-2.1-or-later                                                                      | [17.4.7](https://www.xwiki.org/xwiki/bin/view/ReleaseNotes/Data/XWiki/17.4.7/)                | [For the most recent release](https://www.xwiki.org/xwiki/bin/view/Documentation)                                                     |
| Portal & IAM         | Nubus                       | AGPL-3.0-or-later                                                                      | [1.16.0](https://docs.software-univention.de/nubus-kubernetes-release-notes/1.x/en/1.16.html) | [Univention's documentation website](https://docs.software-univention.de/n/en/nubus.html)                                             |
| Project management   | OpenProject                 | GPL-3.0-only                                                                           | [16.6.5](https://www.openproject.org/docs/release-notes/16-6-5/)                              | [For the most recent release](https://www.openproject.org/docs/user-guide/)                                                           |
| Videoconferencing    | Jitsi                       | Apache-2.0                                                                             | [2.0.10590](https://github.com/jitsi/jitsi-meet/releases/tag/stable%2Fjitsi-meet_10590)       | [For the most recent  release](https://jitsi.github.io/handbook/docs/category/user-guide/)                                            |
| Weboffice            | Collabora                   | MPL-2.0                                                                                | [25.04.7](https://www.collaboraoffice.com/code-25-04-release-notes/)                          | Online documentation available from within the installed application; [Additional resources](https://sdk.collaboraonline.com/)        |

While not all components are perfectly designed for the execution inside containers, one of the project's objectives is to
align the applications with best practices regarding container design and operations.

This documentation aims to give you all that is needed to set up your own instance of the openDesk.

Basic knowledge of Kubernetes and DevOps processes is required though.

# Upgrades

You want to upgrade an existing openDesk installation?

⟶ Visit our detailed documentation about [Updates & Upgrades](./docs/migrations.md).

# Requirements

You want to understand what is required to install openDesk yourself?

⟶ Visit our [Requirements](./docs/requirements.md) overview.

# Getting started

You would like to install openDesk in your own infrastructure?

⟶ Visit our detailed [Getting started guide](./docs/getting-started.md).

# Advanced customization

- [Enhanced Configuration](./docs/enhanced-configuration.md)
- [External services](./docs/external-services.md)
- [Security](./docs/security.md)
- [Scaling](./docs/scaling.md)
- [Monitoring](./docs/monitoring.md)
- [Theming](./docs/theming.md)

# Architecture

More information on openDesk's architecture can be found in our [architecture documentation](./docs/architecture.md).

# Testing

openDesk is continuously tested to ensure it meets high quality standards. Read how we test in openDesk in our [testing concept](./docs/testing.md).

# Permissions

Find out more about the permission system in the [roles & permissions concept](./docs/permissions.md)

# Releases

openDesk implements a defined [release and patch management process](./docs/releases.md) to ensure stability and security.

All technical releases are created using [Semantic Versioning](https://semver.org/).

Gitlab provides an
[overview on the releases](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/releases)
of this project.

Please find a list of the artifacts related to the release either in the source code archive attached to the release or
in the files from the release's git-tag:
- `./helmfile/environments/default/images.yaml.gotmpl`
- `./helmfile/environments/default/charts.yaml.gotmpl`

Find more information in our [Workflow documentation](./docs/developer/workflow.md).

# Data storage

More information about different data storages used within openDesk are described in the
[Data Storage documentation](./docs/data-storage.md).

# Feedback

We love to get feedback from you!

For feedback related to the deployment / contents of this repository,
please use the [issues within this project](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/issues).

If you want to address other topics, please check the section
["Rückmeldungen und Beteiligung" in the OVERVIEW.md](https://gitlab.opencode.de/bmi/opendesk/info/-/blob/main/OVERVIEW.md#rückmeldungen-und-beteiligung) of the [openDesk Info Repository](https://gitlab.opencode.de/bmi/opendesk/info).

# Development

If you want to join or contribute to the development of openDesk please read the [Development guide](./docs/developer/development.md).

# License

This project uses the following license: Apache-2.0

# Copyright

Copyright (C) 2024-2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
