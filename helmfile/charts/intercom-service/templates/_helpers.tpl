{{/*
SPDX-FileCopyrightText: 2023-2025 Univention GmbH
SPDX-License-Identifier: AGPL-3.0-only
*/}}
{{- define "intercom-service.fqdn" -}}
{{- if .Values.ingress.enabled }}
{{ .Values.ics.default.protocol }}://{{ .Values.ingress.host }}
{{- else }}
http://{{ include "common.names.fullname" $ }}:{{ $.Values.service.ports.http.port }}
{{- end }}
{{- end }}
