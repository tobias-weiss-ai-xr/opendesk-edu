# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: AGPL-3.0-or-later

{{- define "f13.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "f13.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "f13.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "f13.labels" -}}
helm.sh/chart: {{ include "f13.chart" . }}
{{ include "f13.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "f13.selectorLabels" -}}
app.kubernetes.io/name: {{ include "f13.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "f13.componentLabels" -}}
{{- $root := .root -}}
{{ include "f13.selectorLabels" $root }}
app.kubernetes.io/component: {{ .component | quote }}
{{- end -}}

{{- define "f13.keycloakUrl" -}}
{{- if .Values.authentication.keycloakBaseUrl -}}
{{- .Values.authentication.keycloakBaseUrl -}}
{{- else if .Values.global.keycloakUrl -}}
{{- .Values.global.keycloakUrl -}}
{{- else -}}
{{- printf "https://keycloak" -}}
{{- end -}}
{{- end -}}

{{- define "f13.keycloakRealm" -}}
{{- if .Values.authentication.keycloakRealm -}}
{{- .Values.authentication.keycloakRealm -}}
{{- else if .Values.global.keycloakRealm -}}
{{- .Values.global.keycloakRealm -}}
{{- else -}}
opendesk
{{- end -}}
{{- end -}}

{{- define "f13.keycloakIssuer" -}}
{{- printf "%s/realms/%s" (include "f13.keycloakUrl" .) (include "f13.keycloakRealm" .) -}}
{{- end -}}

{{- define "f13.keycloakJwksUrl" -}}
{{- printf "%s/protocol/openid-connect/certs" (include "f13.keycloakIssuer" .) -}}
{{- end -}}

{{- define "f13.image" -}}
{{- $registry := .Values.global.imageRegistry -}}
{{- $image := .imageRef -}}
{{- printf "%s/%s:%s" $registry $image.repository $image.tag -}}
{{- end -}}

{{- define "f13.elasticHost" -}}
{{- if .Values.elasticsearch.existingHost -}}
{{- .Values.elasticsearch.existingHost -}}
{{- else -}}
{{- printf "%s-elasticsearch" (include "f13.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "f13.feedbackDbHost" -}}
{{- printf "%s-feedback-db" (include "f13.fullname" .) -}}
{{- end -}}

{{- define "f13.transcriptionDbHost" -}}
{{- printf "%s-transcription-db" (include "f13.fullname" .) -}}
{{- end -}}

{{- define "f13.rabbitmqHost" -}}
{{- printf "%s-rabbitmq" (include "f13.fullname" .) -}}
{{- end -}}
