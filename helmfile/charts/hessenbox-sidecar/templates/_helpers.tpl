{{/*
Expanded template helper functions for hessenbox-sidecar
*/}}

{{- define "hessenbox-sidecar.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hessenbox-sidecar.fullname" -}}
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

{{- define "hessenbox-sidecar.labels" -}}
helm.sh/chart: {{ include "hessenbox-sidecar.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "hessenbox-sidecar.selectorLabels" . }}
{{- if .Chart.AppVersion -}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote -}}
{{- end -}}
app.kubernetes.io/managed-by: {{ .Release.Service -}}
{{- end -}}

{{- define "hessenbox-sidecar.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hessenbox-sidecar.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "hessenbox-sidecar.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "hessenbox-sidecar.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "hessenbox-sidecar.rcloneConfig" -}}
[hessenbox]
type = webdav
url = {{ .Values.hessenbox.url | quote }}
vendor = nextcloud
user = {{ .Values.hessenbox.username | quote }}
pass = {{ .Values.hessenbox.password | quote }}
{{- if .Values.hessenbox.extraConfig -}}
{{- .Values.hessenbox.extraConfig | nindent 0 -}}
{{- end -}}
{{- end -}}
