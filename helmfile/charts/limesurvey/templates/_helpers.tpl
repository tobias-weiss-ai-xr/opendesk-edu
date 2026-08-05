# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
{{/*
Expand the name of the release.
*/}}
{{- define "limesurvey.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "limesurvey.labels" -}}
app.kubernetes.io/name: {{ include "limesurvey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "limesurvey.selectorLabels" -}}
app.kubernetes.io/name: {{ include "limesurvey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
DB Host generator
*/}}
{{- define "limesurvey.dbHost" -}}
{{-   if .Values.limesurvey.db.host }}
{{- .Values.limesurvey.db.host }}
{{-   else }}
{{- .Release.Name }}-mariadb
{{-   end -}}
{{- end -}}

{{/*
DB Username generator
*/}}
{{- define "limesurvey.dbUser" -}}
{{-   if .Values.limesurvey.db.user }}
{{- .Values.limesurvey.db.user }}
{{-   else }}
{{- .Values.mariadb.auth.username }}
{{-   end -}}
{{- end -}}

{{/*
DB Password generator
*/}}
{{- define "limesurvey.dbPassword" -}}
{{-   if .Values.limesurvey.db.password }}
{{- .Values.limesurvey.db.password }}
{{-   else }}
{{- .Values.mariadb.auth.password }}
{{-   end -}}
{{- end -}}

{{/*
DB Name generator
*/}}
{{- define "limesurvey.dbName" -}}
{{-   if .Values.limesurvey.db.name }}
{{- .Values.limesurvey.db.name }}
{{-   else }}
{{- .Values.mariadb.auth.database }}
{{-   end -}}
{{- end -}}

{{/*
DB Port generator
*/}}
{{- define "limesurvey.dbPort" -}}
{{-   if .Values.limesurvey.db.port }}
{{- .Values.limesurvey.db.port }}
{{-   else }}
3306
{{-   end -}}
{{- end -}}

{{/*
Render templates from values.yaml .
Code from https://github.com/bitnami/charts/blob/e77870b5c15230186ce3091f2b620b7de986999f/bitnami/common/templates/_tplvalues.tpl
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}
{{- define "common.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}
