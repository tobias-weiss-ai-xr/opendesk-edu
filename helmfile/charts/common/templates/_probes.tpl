{{- define "common.probes.http" -}}
livenessProbe:
  httpGet:
    path: {{ .path | default "/health" }}
    port: {{ .port | default 80 }}
  initialDelaySeconds: {{ .initialDelaySeconds | default 30 }}
  periodSeconds: {{ .periodSeconds | default 10 }}
readinessProbe:
  httpGet:
    path: {{ .path | default "/health" }}
    port: {{ .port | default 80 }}
  initialDelaySeconds: {{ .initialDelaySeconds | default 5 }}
  periodSeconds: {{ .periodSeconds | default 5 }}
{{- end -}}

{{- define "common.probes.tcp" -}}
livenessProbe:
  tcpSocket:
    port: {{ .port | default 80 }}
  initialDelaySeconds: {{ .initialDelaySeconds | default 30 }}
  periodSeconds: {{ .periodSeconds | default 10 }}
readinessProbe:
  tcpSocket:
    port: {{ .port | default 80 }}
  initialDelaySeconds: {{ .initialDelaySeconds | default 5 }}
  periodSeconds: {{ .periodSeconds | default 5 }}
{{- end -}}
