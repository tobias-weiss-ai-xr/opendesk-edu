# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
{{/*
Expand the name of the release.
*/}}
{{- define "grommunio.name" -}}
{{-   default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "grommunio.labels" -}}
app.kubernetes.io/name: {{ include "grommunio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{-   if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{-   end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "grommunio.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grommunio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Fullname — release-name-chart-name
*/}}
{{- define "grommunio.fullname" -}}
{{-   .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

{{/*
MariaDB URL from db values
*/}}
{{- define "grommunio.dbUrl" -}}
mysql://{{ .Values.grommunio.db.user }}:{{ .Values.grommunio.db.password }}@{{ .Values.grommunio.db.host }}:{{ .Values.grommunio.db.port }}/{{ .Values.grommunio.db.name }}
{{- end -}}

{{/*
Redis URL from cache values
*/}}
{{- define "grommunio.redisUrl" -}}
redis://{{ .Values.grommunio.cache.host }}:{{ .Values.grommunio.cache.port }}
{{- end -}}

{{/*
Keycloak OIDC configuration
*/}}
{{- define "grommunio.oidcIssuer" -}}
{{ .Values.grommunio.auth.oidc.issuerUrl }}
{{- end -}}

{{- define "grommunio.oidcClientId" -}}
{{ .Values.grommunio.auth.oidc.clientId }}
{{- end -}}

{{- define "grommunio.oidcClientSecret" -}}
{{ .Values.grommunio.auth.oidc.clientSecret }}
{{- end -}}

{{/*
Protocol endpoints
*/}}
{{- define "grommunio.activesyncUrl" -}}
{{ .Values.grommunio.ingress.hostname }}/Microsoft-Server-ActiveSync
{{- end -}}

{{- define "grommunio.ewsUrl" -}}
{{ .Values.grommunio.ingress.hostname }}/EWS/Exchange.asmx
{{- end -}}

{{- define "grommunio.mapiUrl" -}}
{{ .Values.grommunio.ingress.hostname }}/mapi/http/
{{- end -}}

{{/*
Image pull secrets
*/}}
{{- define "grommunio.imagePullSecrets" -}}
{{-   with .Values.global.imagePullSecrets }}
imagePullSecrets:
{{-     toYaml . | nindent 2 }}
{{-   end }}
{{- end -}}

{{/*
Create container image
*/}}
{{- define "grommunio.image" -}}
{{-   printf "%s:%s" .Values.grommunio.image.repository (default .Chart.AppVersion .Values.grommunio.image.tag) -}}
{{- end -}}

{{/*
LDAP URL from grommunio.ldap values
*/}}
{{- define "grommunio.ldapUrl" -}}
ldap://{{ .Values.grommunio.ldap.host }}:{{ .Values.grommunio.ldap.port }}
{{- end -}}

{{/*
OIDC Discovery URL from grommunio.auth.oidc values
*/}}
{{- define "grommunio.oidcDiscoveryUrl" -}}
{{ .Values.grommunio.auth.oidc.issuerUrl }}/.well-known/openid-configuration
{{- end -}}

{{/*
Resource requests and limits
*/}}
{{- define "grommunio.resources" -}}
requests:
  cpu: {{ .Values.grommunio.resources.requests.cpu }}
  memory: {{ .Values.grommunio.resources.requests.memory }}
limits:
  cpu: {{ .Values.grommunio.resources.limits.cpu }}
  memory: {{ .Values.grommunio.resources.limits.memory }}
{{- end -}}
