# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

{{/*
Expand the name of the chart.
*/}}
{{- define "typo3.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "typo3.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "typo3.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "typo3.labels" -}}
helm.sh/chart: {{ include "typo3.chart" . }}
{{ include "typo3.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "typo3.selectorLabels" -}}
app.kubernetes.io/name: {{ include "typo3.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "typo3.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- default (include "typo3.fullname" .) .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
DB Host generator
*/}}
{{- define "typo3.dbHost" -}}
{{-   if .Values.typo3.db.host }}
{{- .Values.typo3.db.host }}
{{-   else }}
{{- .Release.Name }}-mariadb
{{-   end -}}
{{- end -}}

{{/*
DB Port generator
*/}}
{{- define "typo3.dbPort" -}}
{{- .Values.typo3.db.port | default 3306 -}}
{{- end -}}

{{/*
DB Username generator
*/}}
{{- define "typo3.dbUser" -}}
{{-   if .Values.typo3.db.user }}
{{- .Values.typo3.db.user }}
{{-   else }}
{{- .Values.mariadb.auth.username }}
{{-   end -}}
{{- end -}}

{{/*
DB Password generator
*/}}
{{- define "typo3.dbPassword" -}}
{{-   if .Values.typo3.db.password }}
{{- .Values.typo3.db.password }}
{{-   else }}
{{- .Values.mariadb.auth.password }}
{{-   end -}}
{{- end -}}

{{/*
DB Name generator
*/}}
{{- define "typo3.dbName" -}}
{{-   if .Values.typo3.db.name }}
{{- .Values.typo3.db.name }}
{{-   else }}
{{- .Values.mariadb.auth.database }}
{{-   end -}}
{{- end -}}
