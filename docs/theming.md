<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Theming</h1>

This document will cover the theming options for an openDesk deployment.

<!-- TOC -->
* [Settings](#settings)
* [Known limitations](#known-limitations)
<!-- TOC -->

# Settings

All default settings can be found in the [`theme.gotmpl`](../helmfile/environments/default/theme.gotmpl). Most of the components adhere to these settings.

Please review the default configuration that is applied to understand your customization options.

You can just update the files in:
- [helmfile/files/theme](../helmfile/files/theme): To change logos, favicons etc.
- [helmfile/files/portal-tiles](../helmfile/files/portal-tiles): To change the icons in the portal.

# Known limitations

Not all applications support theming. Known exceptions are:
- OpenProject, comes with a build in openDesk theming that can be modified in the Enterprise version's OpenProject web interface.
- The portal background logo can (currently) only be set on initial deployment.
- Portal and Keycloak screen styles must be applied in the [`portalStylesheets.css`](../helmfile/files/theme/portalStylesheet.css).
