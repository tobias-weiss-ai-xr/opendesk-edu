# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

{{/*
Expand the name of the chart.
*/}}
{{- define "self-service-password.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "self-service-password.labels" -}}
app.kubernetes.io/name: {{ include "self-service-password.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "self-service-password.selectorLabels" -}}
app.kubernetes.io/name: {{ include "self-service-password.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
