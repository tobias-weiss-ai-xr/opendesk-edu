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
{{- .Values.planka.db.host | default (printf "%s-postgresql" .Release.Name) -}}
{{- end -}}

{{/*
DB Username generator
*/}}
{{- define "planka.dbUser" -}}
{{- .Values.planka.db.user | default "planka" -}}
{{- end -}}

{{/*
DB Password generator
*/}}
{{- define "planka.dbPassword" -}}
{{- .Values.planka.db.password | default "" -}}
{{- end -}}

{{/*
DB Name generator
*/}}
{{- define "planka.dbName" -}}
{{- .Values.planka.db.name | default "planka" -}}
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
