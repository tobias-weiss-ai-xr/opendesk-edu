#!/bin/sh
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

yq eval '
  (. | select(.kind == "StatefulSet")
     | select(.metadata.name == "ox-connector")
     | .spec.volumeClaimTemplates[]
     | select(.metadata.name == "ox-connector-ox-contexts"
           or .metadata.name == "ox-connector-appcenter")
     | .spec.storageClassName) |=
    (del(.) // .)
' -