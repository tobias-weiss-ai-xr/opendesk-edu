# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: GPL-3.0-or-later
{{/*
Expand the name of the chart.
*/}}
{{- define "paperless-ngx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "paperless-ngx.fullname" -}}
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
{{- define "paperless-ngx.labels" -}}
helm.sh/chart: {{ include "paperless-ngx.chart" . }}
{{ include "paperless-ngx.selectorLabels" . }}
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
{{- define "paperless-ngx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "paperless-ngx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "paperless-ngx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the secret for database credentials
*/}}
{{- define "paperless-ngx.databaseSecret" -}}
{{- default (include "paperless-ngx.fullname" .) .Values.paperless.database.existingSecret -}}
{{- end -}}

{{/*
Return the secret for Redis credentials
*/}}
{{- define "paperless-ngx.redisSecret" -}}
{{- default (printf "%s-redis" (include "paperless-ngx.fullname" .)) .Values.paperless.redis.existingSecret -}}
{{- end -}}

{{/*
Return the secret for OIDC credentials
*/}}
{{- define "paperless-ngx.oidcSecret" -}}
{{- default (printf "%s-oidc" (include "paperless-ngx.fullname" .)) .Values.paperless.oidc.existingSecret -}}
{{- end -}}

{{/*
Return the secret for admin credentials
*/}}
{{- define "paperless-ngx.adminSecret" -}}
{{- default (printf "%s-admin" (include "paperless-ngx.fullname" .)) "" -}}
{{- end -}}

{{/*
Return the secret for email credentials
*/}}
{{- define "paperless-ngx.emailSecret" -}}
{{- default (printf "%s-email" (include "paperless-ngx.fullname" .)) .Values.paperless.email.existingSecret -}}
{{- end -}}

{{/*
Service account name
*/}}
{{- define "paperless-ngx.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- default (include "paperless-ngx.fullname" .) .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
