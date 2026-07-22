#!/bin/sh
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

yq eval --string-interpolation=false --exit-status --expression '
  select(.kind == "Ingress") |= (
    .spec.rules[].http.paths[] |=
      (select(.path | test("\(\.\*\)$")) | .path |= sub("\(\.\*\)$"; "") | .pathType = "Prefix") // .
  )
' -
