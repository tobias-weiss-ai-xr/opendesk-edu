# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

{{/*
Expand the name of the chart.
*/}}
{{- define "drawio.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "drawio.labels" -}}
app.kubernetes.io/name: {{ include "drawio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "drawio.selectorLabels" -}}
app.kubernetes.io/name: {{ include "drawio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
