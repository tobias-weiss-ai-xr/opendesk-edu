{{/*
Expand the name of the release.
*/}}
{{- define "zammad.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "zammad.labels" -}}
app.kubernetes.io/name: {{ include "zammad.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "zammad.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zammad.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
PostgreSQL Host generator
*/}}
{{- define "zammad.dbHost" -}}
{{-   if .Values.zammad.db.host }}
{{- .Values.zammad.db.host }}
{{-   else if .Values.postgresql.enabled }}
{{- .Release.Name }}-postgresql
{{-   end -}}
{{- end -}}

{{/*
PostgreSQL User generator
*/}}
{{- define "zammad.dbUser" -}}
{{-   if .Values.zammad.db.user }}
{{- .Values.zammad.db.user }}
{{-   else if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.username }}
{{-   end -}}
{{- end -}}

{{/*
PostgreSQL Password generator
*/}}
{{- define "zammad.dbPassword" -}}
{{-   if .Values.zammad.db.password }}
{{- .Values.zammad.db.password }}
{{-   else if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.password }}
{{-   end -}}
{{- end -}}

{{/*
PostgreSQL Database Name generator
*/}}
{{- define "zammad.dbName" -}}
{{-   if .Values.zammad.db.name }}
{{- .Values.zammad.db.name }}
{{-   else if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.database }}
{{-   end -}}
{{- end -}}

{{/*
Elasticsearch Host generator
*/}}
{{- define "zammad.esHost" -}}
{{-   if .Values.zammad.elasticsearch.host }}
{{- .Values.zammad.elasticsearch.host }}
{{-   else if .Values.elasticsearch.enabled }}
{{- .Release.Name }}-elasticsearch
{{-   end -}}
{{- end -}}

{{/*
Elasticsearch Port generator
*/}}
{{- define "zammad.esPort" -}}
{{-   if .Values.zammad.elasticsearch.port }}
{{- .Values.zammad.elasticsearch.port }}
{{-   else if .Values.elasticsearch.enabled }}
{{- .Values.elasticsearch.service.ports.http | default 9200 }}
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
