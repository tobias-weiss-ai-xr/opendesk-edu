{{/*
Expand the name of the release.
*/}}
{{- define "ilias.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "ilias.labels" -}}
app.kubernetes.io/name: {{ include "ilias.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "ilias.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ilias.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
DB Host generator
*/}}
{{- define "ilias.dbHost" -}}
{{-   if .Values.ilias.db.host }}
{{- .Values.ilias.db.host }}
{{-   else if .Values.mariadbgalera.enabled }}
{{- .Release.Name }}-mariadbgalera
{{-   else }}
{{- .Release.Name }}-mariadb
{{-   end -}}
{{- end -}}


{{/*
DB Username generator
*/}}
{{- define "ilias.dbUser" -}}
{{-   if .Values.ilias.db.user }}
{{- .Values.ilias.db.user }}
{{-   else if .Values.mariadbgalera.enabled }}
{{- .Values.mariadbgalera.db.user }}
{{-   else }}
{{- .Values.mariadb.auth.username }}
{{-   end -}}
{{- end -}}


{{/*
DB Password generator
*/}}
{{- define "ilias.dbPassword" -}}
{{-   if .Values.ilias.db.password }}
{{- .Values.ilias.db.user }}
{{-   else if .Values.mariadbgalera.enabled }}
{{- .Values.mariadbgalera.db.password }}
{{-   else }}
{{- .Values.mariadb.auth.password }}
{{-   end -}}
{{- end -}}


{{/*
DB Name generator
*/}}
{{- define "ilias.dbName" -}}
{{-   if .Values.ilias.db.name }}
{{- .Values.ilias.db.user }}
{{-   else if .Values.mariadbgalera.enabled }}
{{- .Values.mariadbgalera.db.name }}
{{-   else }}
{{- .Values.mariadb.auth.database }}
{{-   end -}}
{{- end -}}

{{/*
MariaDB image
*/}}
{{- define "mariadbImage" -}}
{{-   if .Values.mariadbgalera.enabled }}
{{- .Values.mariadbgalera.image.repository }}:{{ .Values.mariadbgalera.image.tag }}
{{-   else if .Values.mariadb.enabled }}
{{- .Values.mariadb.image.repository }}:{{ .Values.mariadb.image.tag }}
{{-   else }}
{{- .Values.ilias.image }}:{{ .Values.ilias.tag }}
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
