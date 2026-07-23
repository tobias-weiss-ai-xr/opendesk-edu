# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
{{/*
Expand the name of the release.
*/}}
{{- define "etherpad.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "etherpad.labels" -}}
app.kubernetes.io/name: {{ include "etherpad.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "etherpad.selectorLabels" -}}
app.kubernetes.io/name: {{ include "etherpad.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
DB Host generator
*/}}
{{- define "etherpad.dbHost" -}}
{{-   if .Values.etherpad.db.host }}
{{- .Values.etherpad.db.host }}
{{-   else }}
{{- .Release.Name }}-postgresql
{{-   end -}}
{{- end -}}

{{/*
DB Username generator
*/}}
{{- define "etherpad.dbUser" -}}
{{-   if .Values.etherpad.db.user }}
{{- .Values.etherpad.db.user }}
{{-   else }}
{{- .Values.postgresql.auth.username }}
{{-   end -}}
{{- end -}}

{{/*
DB Password generator
*/}}
{{- define "etherpad.dbPassword" -}}
{{-   if .Values.etherpad.db.password }}
{{- .Values.etherpad.db.password }}
{{-   else if .Values.etherpad.db.existingSecret }}
{{- "" }}
{{-   else }}
{{- "" }}
{{-   end -}}
{{- end -}}

{{/*
DB Name generator
*/}}
{{- define "etherpad.dbName" -}}
{{-   if .Values.etherpad.db.name }}
{{- .Values.etherpad.db.name }}
{{-   else }}
{{- .Values.postgresql.auth.database }}
{{-   end -}}
{{- end -}}
