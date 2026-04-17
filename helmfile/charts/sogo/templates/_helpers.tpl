# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
{{/*
Expand the name of the release.
*/}}
{{- define "sogo.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "sogo.labels" -}}
app.kubernetes.io/name: {{ include "sogo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "sogo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sogo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Fullname — release-name-chart-name
*/}}
{{- define "sogo.fullname" -}}
{{-   .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

{{/*
PostgreSQL URL from db values
SOGo expects: postgresql://user:pass@host:port/database?sslmode=disable
*/}}
{{- define "sogo.dbUrl" -}}
postgresql://{{ .Values.sogo.db.user }}:{{ .Values.sogo.db.password }}@{{ .Values.sogo.db.host }}:{{ .Values.sogo.db.port }}/{{ .Values.sogo.db.name }}
{{- end -}}

{{/*
LDAP URL from ldap values
*/}}
{{- define "sogo.ldapUrl" -}}
ldap://{{ .Values.sogo.ldap.host }}:{{ .Values.sogo.ldap.port }}
{{- end -}}
