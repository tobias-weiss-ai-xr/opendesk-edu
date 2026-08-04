{{- define "dev-dns.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "dev-dns.fullname" -}}
{{- if .Values.fullnameOverride }}{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}{{- end }}{{- end }}{{- end }}
{{- define "dev-dns.labels" -}}
helm.sh/chart: {{ include "dev-dns.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "dev-dns.selectorLabels" . }}{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}{{- end }}
{{- define "dev-dns.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dev-dns.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}{{- end }}