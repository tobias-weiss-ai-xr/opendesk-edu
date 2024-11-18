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
* [Components](#components)
* [Releases](#releases)
* [Feedback](#feedback)
* [Development](#development)
* [License](#license)
* [Copyright](#copyright)
<!-- TOC -->

# Overview

openDesk is a Kubernetes based, open-source and cloud-native digital workplace suite provided by the
*Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH*.

openDesk currently features the following functional main components:

| Function             | Functional Component        | Component<br/>Version                                                                 | Upstream Documentation                                                                                                               |
| -------------------- | --------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Chat & collaboration | Element ft. Nordeck widgets | [1.11.67](https://github.com/element-hq/element-desktop/releases/tag/v1.11.67)        | [For the most recent release](https://element.io/user-guide)                                                                         |
| Diagram editor       | CryptPad ft. diagrams.net   | [5.6.0](https://github.com/cryptpad/cryptpad/releases/tag/5.6.0)                      | [For the most recent release](https://docs.cryptpad.org/en/)                                                                         |
| File management      | Nextcloud                   | [29.0.9](https://nextcloud.com/de/changelog/#29-0-9)                                  | [Nextcloud 29](https://docs.nextcloud.com/)                                                                                         |
| Groupware            | OX App Suite                | [8.30](https://documentation.open-xchange.com/appsuite/releases/8.30/)                | Online documentation available from within the installed application; [Additional resources](https://documentation.open-xchange.com/) |
| Knowledge management | XWiki                       | [16.4.4](https://www.xwiki.org/xwiki/bin/view/ReleaseNotes/Data/XWiki/16.4.4/)        | [For the most recent release](https://www.xwiki.org/xwiki/bin/view/Documentation)                                                    |
| Portal & IAM         | Nubus                       | [1.0](https://www.univention.de/produkte/nubus/)                                      | [Univention's documentation website](https://docs.software-univention.de/n/en/nubus.html)                                            |
| Project management   | OpenProject                 | [15.0.2](https://www.openproject.org/docs/release-notes/15-0-2/)                      | [For the most recent release](https://www.openproject.org/docs/user-guide/)                                                          |
| Videoconferencing    | Jitsi                       | [2.0.9779](https://github.com/jitsi/jitsi-meet/releases/tag/stable%2Fjitsi-meet_9779) | [For the most recent  release](https://jitsi.github.io/handbook/docs/category/user-guide/)                                           |
| Weboffice            | Collabora                   | [24.04.7.2](https://www.collaboraoffice.com/code-24-04-release-notes/)                | Online documentation available from within the installed application; [Additional resources](https://sdk.collaboraonline.com/)       |

While not all components are perfectly shaped for the execution inside containers, one of the project's objectives is to
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

# Components

More information on openDesk's components and their integration can be found in our detailed [Component docs](./docs/components.md).

# Releases

All technical releases are created using [Semantic Versioning](https://semver.org/lang/de/).

Gitlab provides an
[overview on the releases](https://gitlab.opencode.de/bmi/opendesk/deployment/sovereign-workplace/-/releases)
of this project.

Please find a list of the artifacts related to the release either in the source code archive attached to the release or
in the files from the release's git-tag:
- `./helmfile/environments/default/images.yaml`
- `./helmfile/environments/default/charts.yaml`

Find more information in our [Workflow documentation](./docs/workflow.md).

# Feedback

We love to get feedback from you!

Related to the deployment / contents of this repository,
please use the [issues within this project](https://gitlab.opencode.de/bmi/opendesk/deployment/sovereign-workplace/-/issues).

If you want to address other topics, please check the section
["Rückmeldungen und Beteiligung" in the OVERVIEW.md](https://gitlab.opencode.de/bmi/opendesk/info/-/blob/main/OVERVIEW.md#rückmeldungen-und-beteiligung) of the [openDesk Info Repository](https://gitlab.opencode.de/bmi/opendesk/info).

# Development

If you want to join or contribute to the development of openDesk please read the [Development guide](./docs/development.md).

# License

This project uses the following license: Apache-2.0

# Copyright

Copyright (C) 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
