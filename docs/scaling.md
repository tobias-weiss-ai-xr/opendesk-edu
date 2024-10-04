<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Scaling</h1>

This document should cover the ability to scale apps.

# Horizontal scalability

We are working on generating this document automatically based on the file
[`replicas.yaml`](../helmfile/environments/default/replicas.yaml) that contains necessary annotations.
In the meantime, this file can be used to check the components scaling support/capabilities.

# Upstream information

While scaling services horizontally is the ideal solution, information about vertical scaling is helpful
when defining the application's resources, see [`resources.yaml`](../helmfile/environments/default/resources.yaml) for references.

Please find below links to the application's upstream resources about scaling:

- [OpenProject system requirements](https://www.openproject.org/docs/installation-and-operations/system-requirements/)
