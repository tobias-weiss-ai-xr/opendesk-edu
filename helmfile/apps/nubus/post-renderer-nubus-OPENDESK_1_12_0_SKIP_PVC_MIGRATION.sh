#!/bin/sh
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

yq eval '
  (
    select(.kind == "StatefulSet" and .metadata.name == "ums-provisioning-nats")
    .spec.volumeClaimTemplates[]
    | select(.metadata.name == "nats-data")
    | .spec.storageClassName
  ) = null
  |
  (
    select(.kind == "StatefulSet" and .metadata.name == "ums-provisioning-udm-listener")
    .spec.volumeClaimTemplates[]
    | select(.metadata.name == "data")
    | .spec.storageClassName
  ) = null
' -