{{- define "common.deployment" -}}
{{-   $name := .name -}}
{{-   $image := .image -}}
{{-   $tag := .tag | default "latest" -}}
{{-   $port := .port | default 80 -}}
{{-   $replicas := .replicas | default 1 -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $name }}
  labels:
    app.kubernetes.io/name: {{ $name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ $replicas }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $name }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ $name }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      securityContext:
        {{- include "common.security.podContext" . | nindent 8 }}
      containers:
        - name: {{ $name }}
          image: "{{ $image }}:{{ $tag }}"
          imagePullPolicy: {{ .imagePullPolicy | default "IfNotPresent" }}
          ports:
            - name: http
              containerPort: {{ $port }}
          securityContext:
            {{- include "common.security.context" . | nindent 12 }}
            {{- include "common.security.capabilities" . | nindent 12 }}
          env:
            {{- toYaml (.env | default list) | nindent 12 }}
          resources:
            {{- include "common.resources" . | nindent 12 }}
          {{- include "common.probes.tcp" (dict "port" $port) | nindent 10 }}
{{- end -}}
