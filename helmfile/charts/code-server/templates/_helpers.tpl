{{- define "code-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "code-server.fullname" -}}
{{- if .Values.fullnameOverride }}{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}{{- end }}{{- end }}{{- end }}
{{- define "code-server.labels" -}}
helm.sh/chart: {{ include "code-server.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "code-server.selectorLabels" . }}{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}{{- end }}
{{- define "code-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "code-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}{{- end }}
