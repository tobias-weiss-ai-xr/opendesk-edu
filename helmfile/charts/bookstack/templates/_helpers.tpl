# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

{{/*
Expand the name of the release.
*/}}
{{- define "bookstack.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "bookstack.labels" -}}
app.kubernetes.io/name: {{ include "bookstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "bookstack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bookstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
DB Host generator
*/}}
{{- define "bookstack.dbHost" -}}
{{-   if .Values.bookstack.db.host }}
{{- .Values.bookstack.db.host }}
{{-   else }}
{{- .Release.Name }}-mariadb
{{-   end -}}
{{- end -}}

{{/*
DB Port generator
*/}}
{{- define "bookstack.dbPort" -}}
{{- .Values.bookstack.db.port | default 3306 -}}
{{- end -}}

{{/*
DB Username generator
*/}}
{{- define "bookstack.dbUser" -}}
{{-   if .Values.bookstack.db.user }}
{{- .Values.bookstack.db.user }}
{{-   else }}
{{- .Values.mariadb.auth.username }}
{{-   end -}}
{{- end -}}

{{/*
DB Password generator
*/}}
{{- define "bookstack.dbPassword" -}}
{{-   if .Values.bookstack.db.password }}
{{- .Values.bookstack.db.password }}
{{-   else }}
{{- .Values.mariadb.auth.password }}
{{-   end -}}
{{- end -}}

{{/*
DB Name generator
*/}}
{{- define "bookstack.dbName" -}}
{{-   if .Values.bookstack.db.name }}
{{- .Values.bookstack.db.name }}
{{-   else }}
{{- .Values.mariadb.auth.database }}
{{-   end -}}
{{- end -}}
