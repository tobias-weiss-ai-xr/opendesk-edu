# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
{{/*
Expand the name of the chart.
*/}}
{{- define "stalwart.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "stalwart.labels" -}}
app.kubernetes.io/name: {{ include "stalwart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "stalwart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stalwart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Fullname — release-name-chart-name
*/}}
{{- define "stalwart.fullname" -}}
{{-   .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

{{/*
Image pull secrets
*/}}
{{- define "stalwart.imagePullSecrets" -}}
{{-   with .Values.global.imagePullSecrets }}
imagePullSecrets:
{{-     toYaml . | nindent 2 }}
{{-   end }}
{{- end -}}

{{/*
Container image
*/}}
{{- define "stalwart.image" -}}
{{-   $registry := coalesce .Values.stalwart.image.registry .Values.global.imageRegistry -}}
{{-   $repository := .Values.stalwart.image.repository -}}
{{-   $tag := default .Chart.AppVersion .Values.stalwart.image.tag -}}
{{-   if $registry -}}
{{-     printf "%s/%s:%s" $registry $repository $tag -}}
{{-   else -}}
{{-     printf "%s:%s" $repository $tag -}}
{{-   end -}}
{{- end -}}

{{/*
ConfigMap name
*/}}
{{- define "stalwart.configmap" -}}
{{-   include "stalwart.fullname" . -}}-config
{{- end -}}

{{/*
PVC name
*/}}
{{- define "stalwart.pvc" -}}
{{-   include "stalwart.fullname" . -}}-pvc
{{- end -}}
