#!/bin/sh
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

yq eval --exit-status --expression '
  (. | select(.kind == "Ingress") | select(.metadata.name == "open-xchange-appsuite-http-api-routes-appsuite-api") | .spec.rules[].http.paths[].path) |=
    (select(. == "/appsuite/api(.*)") | "/appsuite/api") // .
' -
