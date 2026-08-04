{{/*
Expand the name of the release.
*/}}
{{- define "planka.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "planka.labels" -}}
app.kubernetes.io/name: {{ include "planka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "planka.selectorLabels" -}}
app.kubernetes.io/name: {{ include "planka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
DB Host generator
*/}}
{{- define "planka.dbHost" -}}
{{-   if .Values.planka.db.host }}
{{-     .Values.planka.db.host }}
{{-   else }}
{{- .Release.Name }}-postgresql
{{-   end }}
{{- end -}}

{{/*
DB Username generator
*/}}
{{- define "planka.dbUser" -}}
{{-   if .Values.planka.db.user }}
{{-     .Values.planka.db.user }}
{{-   else }}
{{- .Values.postgresql.auth.username -}}
{{-   end }}
{{- end -}}

{{/*\
DB Password generator
*/}}
{{- define "planka.dbPassword" -}}
{{-   if .Values.planka.db.password }}
{{-     .Values.planka.db.password }}
{{-   else }}
{{- .Values.postgresql.auth.password -}}
{{-   end }}
{{- end -}}

{{/*\
DB Name generator
*/}}
{{- define "planka.dbName" -}}
{{-   if .Values.planka.db.name }}
{{-     .Values.planka.db.name }}
{{-   else }}
{{- .Values.postgresql.auth.database -}}
{{-   end }}
{{- end -}}

{{/*
Render templates from values.yaml.
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
