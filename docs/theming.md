<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Theming</h1>

This document will cover the theming and customization of your openDesk deployment.

<!-- TOC -->
  * [Strings and texts](#strings-and-texts)
  * [Colors](#colors)
  * [Images and Logos](#images-and-logos)
  * [Known limits](#known-limits)
<!-- TOC -->

## Strings and texts

The deployment name can be changed by:

```yaml
theme:
  texts:
    productName: "openDesk Cloud"
```

## Colors

The primary color and their derivates with lesser opacity be customized by:

```yaml
theme:
  colors:
    primary: "#5e27dd"
    primary65: "#9673e9"
    primary35: "#c7b3f3"
    primary15: "#e7dffa"
```

## Images and Logos

You can customize the logo and favicon by providing SVG or icon as inline value:

```yaml
theme:
  imagery:
    logoHeaderSvg: '<?xml version="1.0" encoding="UTF-8"?>...</svg>'
    logoHeaderSvgWhite: '<?xml version="1.0" encoding="UTF-8"?>...</svg>'
    logoPortalBackgroundSvg: '<?xml version="1.0" encoding="UTF-8"?>...</svg>'
    faviconIco: "..."
```

## Known limits

Not all applications support theming. Known exceptions are:
  - Univention Corporate Container (should be superseded by the Univention Management Stack which has planned support 
    for theming through the deployment).
  - OpenProject
  - Jitsi
