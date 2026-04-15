{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Expand the name of the chart.
*/}}
{{- define "seaweedfs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Create a default fully qualified app name.
*/}}
{{- define "seaweedfs.fullname" -}}
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

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Create chart name and version as used by the chart label.
*/}}
{{- define "seaweedfs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Common labels
*/}}
{{- define "seaweedfs.labels" -}}
helm.sh/chart: {{ include "seaweedfs.chart" . }}
{{ include "seaweedfs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Selector labels
*/}}
{{- define "seaweedfs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "seaweedfs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Master service name
*/}}
{{- define "seaweedfs.masterFullname" -}}
{{- printf "%s-master" (include "seaweedfs.fullname" .) }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
Volume service name
*/}}
{{- define "seaweedfs.volumeFullname" -}}
{{- printf "%s-volume" (include "seaweedfs.fullname" .) }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
S3 gateway service name
*/}}
{{- define "seaweedfs.s3Fullname" -}}
{{- printf "%s-s3" (include "seaweedfs.fullname" .) }}
{{- end }}
