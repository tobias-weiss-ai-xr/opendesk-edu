# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
{{/*
Expand the name of the chart.
*/}}
{{- define "mayan-edms.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mayan-edms.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mayan-edms.labels" -}}
helm.sh/chart: {{ include "mayan-edms.chart" . }}
{{ include "mayan-edms.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: opendesk-edu
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "mayan-edms.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mayan-edms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mayan-edms.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the secret for database credentials
*/}}
{{- define "mayan-edms.databaseSecret" -}}
{{- default (include "mayan-edms.fullname" .) .Values.mayan.database.existingSecret -}}
{{- end -}}

{{/*
Return the secret for Redis credentials
*/}}
{{- define "mayan-edms.redisSecret" -}}
{{- default (printf "%s-redis" (include "mayan-edms.fullname" .)) .Values.mayan.redis.existingSecret -}}
{{- end -}}

{{/*
Return the secret for OIDC credentials
*/}}
{{- define "mayan-edms.oidcSecret" -}}
{{- default (printf "%s-oidc" (include "mayan-edms.fullname" .)) .Values.mayan.oidc.existingSecret -}}
{{- end -}}

{{/*
Return the secret for email credentials
*/}}
{{- define "mayan-edms.emailSecret" -}}
{{- default (printf "%s-email" (include "mayan-edms.fullname" .)) .Values.mayan.email.existingSecret -}}
{{- end -}}

{{/*
Service account name
*/}}
{{- define "mayan-edms.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- default (include "mayan-edms.fullname" .) .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
