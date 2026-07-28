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
{{- .Values.ilias.db.host | quote }}
{{-   else }}
{{- printf "%s-mariadb" .Release.Name }}
{{-   end -}}
{{- end -}}

{{/*
DB Username generator
*/}}
{{- define "ilias.dbUser" -}}
{{-   .Values.ilias.db.user | default "ilias" | quote -}}
{{- end -}}

{{/*
DB Password generator
*/}}
{{- define "ilias.dbPassword" -}}
{{-   if .Values.ilias.db.password }}
{{- .Values.ilias.db.password | quote }}
{{-   else }}
{{-   "" -}}
{{-   end -}}
{{- end -}}

{{/*
DB Name generator
*/}}
{{- define "ilias.dbName" -}}
{{-   .Values.ilias.db.name | default "ilias" | quote -}}
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

{{/*
Create a fully qualified app name.
*/}}
{{- define "ilias.fullname" -}}
{{- if .Values.ilias.fullnameOverride }}
{{- .Values.ilias.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.ilias.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}
