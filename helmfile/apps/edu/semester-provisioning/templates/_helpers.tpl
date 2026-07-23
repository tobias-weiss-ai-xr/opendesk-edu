# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

{{/*
Expand the name of the chart.
*/}}
{{- define "semester-provisioning.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create fully qualified app name.
*/}}
{{- define "semester-provisioning.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "semester-provisioning.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "semester-provisioning.labels" -}}
helm.sh/chart: {{ include "semester-provisioning.chart" . }}
{{ include "semester-provisioning.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "semester-provisioning.selectorLabels" -}}
app.kubernetes.io/name: {{ include "semester-provisioning.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "semester-provisioning.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "semester-provisioning.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper image name
*/}}
{{- define "semester-provisioning.image" -}}
{{- $registryName := .Values.global.imageRegistry | default .Values.semesterProvisioning.image.registry -}}
{{- $repositoryName := .Values.semesterProvisioning.image.repository -}}
{{- $tag := .Values.semesterProvisioning.image.tag | default .Chart.AppVersion -}}
{{- if $registryName -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress
*/}}
{{- define "semester-provisioning.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end -}}

{{/*
Return if ingress is stable
*/}}
{{- define "semester-provisioning.ingress.isStable" -}}
{{- eq (include "semester-provisioning.ingress.apiVersion" .) "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
ConfigMap name
*/}}
{{- define "semester-provisioning.configMapName" -}}
{{- if .Values.configMap.existingConfigMap -}}
{{- .Values.configMap.existingConfigMap -}}
{{- else -}}
{{- include "semester-provisioning.fullname" . -}}-config
{{- end -}}
{{- end -}}

{{/*
Database connection string
*/}}
{{- define "semester-provisioning.databaseUrl" -}}
{{- if eq .Values.database.type "postgresql" -}}
postgresql://{{ .Values.database.postgresql.user }}:{{ .Values.database.postgresql.password }}@{{ .Values.database.postgresql.host }}:{{ .Values.database.postgresql.port }}/{{ .Values.database.postgresql.database }}
{{- else -}}
sqlite://{{ .Values.database.sqlite_path }}
{{- end -}}
{{- end -}}
