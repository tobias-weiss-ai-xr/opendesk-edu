{{/*
SPDX-FileCopyrightText: 2023-2025 Univention GmbH
SPDX-License-Identifier: AGPL-3.0-only

SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0

This file replaces the vendor dependencies on nubus-common and bitnami/common.
*/}}

{{/*
intercom-service FQDN
*/}}
{{- define "intercom-service.fqdn" -}}
{{- if .Values.ingress.enabled }}
{{ .Values.ics.default.protocol }}://{{ .Values.ingress.host }}
{{- else }}
http://{{ include "common.names.fullname" $ }}:{{ $.Values.service.ports.http.port }}
{{- end }}
{{- end }}

{{/*
common.names.name — Expand the name of the chart.
*/}}
{{- define "common.names.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
common.names.chart — Create chart name and version as used by the chart label.
*/}}
{{- define "common.names.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
common.names.fullname — Create a default fully qualified app name.
*/}}
{{- define "common.names.fullname" -}}
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

{{/*
common.names.namespace — Allow the release namespace to be overridden.
*/}}
{{- define "common.names.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
common.capabilities.kubeVersion — Return the target Kubernetes version.
*/}}
{{- define "common.capabilities.kubeVersion" -}}
{{- default (default .Capabilities.KubeVersion.Version .Values.kubeVersion) ((.Values.global).kubeVersion) -}}
{{- end -}}

{{/*
common.capabilities.deployment.apiVersion — Return the appropriate apiVersion for deployment.
*/}}
{{- define "common.capabilities.deployment.apiVersion" -}}
{{- $kubeVersion := include "common.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.14-0" $kubeVersion) -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
common.capabilities.ingress.apiVersion — Return the appropriate apiVersion for ingress.
*/}}
{{- define "common.capabilities.ingress.apiVersion" -}}
{{- $kubeVersion := include "common.capabilities.kubeVersion" . -}}
{{- if (.Values.ingress).apiVersion -}}
{{- .Values.ingress.apiVersion -}}
{{- else if and (not (empty $kubeVersion)) (semverCompare "<1.14-0" $kubeVersion) -}}
{{- print "extensions/v1beta1" -}}
{{- else if and (not (empty $kubeVersion)) (semverCompare "<1.19-0" $kubeVersion) -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}
{{- end -}}

{{/*
common.labels.standard — Kubernetes standard labels.
Usage: {{ include "common.labels.standard" (dict "customLabels" .Values.commonLabels "context" $) }}
*/}}
{{- define "common.labels.standard" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{- $default := dict "app.kubernetes.io/name" (include "common.names.name" .context) "helm.sh/chart" (include "common.names.chart" .context) "app.kubernetes.io/instance" .context.Release.Name "app.kubernetes.io/managed-by" .context.Release.Service -}}
{{- with .context.Chart.AppVersion -}}
{{- $_ := set $default "app.kubernetes.io/version" . -}}
{{- end -}}
{{- $merged := mergeOverwrite (dict) $default .customLabels -}}
{{- range $k, $v := $merged -}}
{{ $k }}: {{ $v }}
{{- end -}}
{{- else -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
helm.sh/chart: {{ include "common.names.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
common.labels.matchLabels — Selector labels.
Usage: {{ include "common.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" $) }}
*/}}
{{- define "common.labels.matchLabels" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{- $standard := dict "app.kubernetes.io/name" (include "common.names.name" .context) "app.kubernetes.io/instance" .context.Release.Name -}}
{{- $merged := mergeOverwrite (dict) $standard (fromYaml (include "common.tplvalues.render" (dict "value" .customLabels "context" .context))) -}}
{{- range $k, $v := $merged -}}
{{ $k }}: {{ $v }}
{{- end -}}
{{- else -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
common.tplvalues.render — Renders a value that contains template.
Usage: {{ include "common.tplvalues.render" ( dict "value" .Values.path "context" $ ) }}
*/}}
{{- define "common.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) -}}
{{- if contains "{{" (toJson .value) -}}
  {{- if .scope -}}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) -}}
  {{- else -}}
    {{- tpl $value .context -}}
  {{- end -}}
{{- else -}}
    {{- $value -}}
{{- end -}}
{{- end -}}

{{/*
common.ingress.backend — Generate backend entry compatible with all K8s API versions.
Usage: {{ include "common.ingress.backend" (dict "serviceName" "x" "servicePort" "http" "context" $) }}
*/}}
{{- define "common.ingress.backend" -}}
{{- $apiVersion := (include "common.capabilities.ingress.apiVersion" .context) -}}
{{- if or (eq $apiVersion "extensions/v1beta1") (eq $apiVersion "networking.k8s.io/v1beta1") -}}
serviceName: {{ .serviceName }}
servicePort: {{ .servicePort }}
{{- else -}}
service:
  name: {{ .serviceName }}
  port:
    {{- if typeIs "string" .servicePort }}
    name: {{ .servicePort }}
    {{- else if or (typeIs "int" .servicePort) (typeIs "float64" .servicePort) }}
    number: {{ .servicePort | int }}
    {{- end }}
{{- end -}}
{{- end -}}

{{/*
common.ingress.supportsPathType — Print "true" if the API pathType field is supported.
*/}}
{{- define "common.ingress.supportsPathType" -}}
{{- if (semverCompare "<1.18-0" (include "common.capabilities.kubeVersion" .)) -}}
{{- print "false" -}}
{{- else -}}
{{- print "true" -}}
{{- end -}}
{{- end -}}

{{/*
nubus-common.secrets.name — Generate the name of a Secret.
Usage: {{ include "nubus-common.secrets.name" (dict "existingSecret" .Values.x "defaultNameSuffix" "suffix" "context" .) }}
*/}}
{{- define "nubus-common.secrets.name" -}}
{{- $name := printf "%s-%s" (include "common.names.fullname" .context) (default "" .defaultNameSuffix) | trunc 63 | trimSuffix "-" -}}
{{- if (.existingSecret).name -}}
{{- $name = tpl .existingSecret.name .context -}}
{{- end -}}
{{- printf "%s" $name -}}
{{- end -}}

{{/*
nubus-common.secrets.key — Generate the secret key.
Usage: {{ include "nubus-common.secrets.key" (dict "existingSecret" .Values.x "key" "keyName") }}
*/}}
{{- define "nubus-common.secrets.key" -}}
{{- $_ := required "Variable .key is required" .key -}}
{{- default .key (get (.existingSecret).keyMapping .key) -}}
{{- end -}}
