{{- define "opencloud-sidecar.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opencloud-sidecar.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "opencloud-sidecar.labels" -}}
helm.sh/chart: {{ include "opencloud-sidecar.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "opencloud-sidecar.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "opencloud-sidecar.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opencloud-sidecar.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
