{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Expand the name of the chart.
*/}}
{{- define "snipr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Create a default fully qualified app name.
*/}}
{{- define "snipr.fullname" -}}
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
# SPDX-License-Identifier: AGPL-3.0-or-later
Create chart name and version as used by the chart label.
*/}}
{{- define "snipr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Common labels
*/}}
{{- define "snipr.labels" -}}
helm.sh/chart: {{ include "snipr.chart" . }}
{{ include "snipr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Selector labels
*/}}
{{- define "snipr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "snipr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Create the name of the service account to use
*/}}
{{- define "snipr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "snipr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Database host (for future PostgreSQL if needed)
*/}}
{{- define "snipr.dbHost" -}}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Database user
*/}}
{{- define "snipr.dbUser" -}}
{{- default "snipr" .Values.snipr.db.user }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Database password
*/}}
{{- define "snipr.dbPassword" -}}
{{- default "" .Values.snipr.db.password }}
{{- end }}

{{/*
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: AGPL-3.0-or-later
Database name
*/}}
{{- define "snipr.dbName" -}}
{{- default "snipr" .Values.snipr.db.name }}
{{- end }}
