{{- define "common.security.context" -}}
{{-   $defaults := dict "allowPrivilegeEscalation" false "runAsNonRoot" true "runAsUser" 1000 "runAsGroup" 1000 "privileged" false -}}
{{-   $custom := .Values.securityContext | default dict -}}
{{-   mergeOverwrite $defaults $custom | toYaml -}}
{{- end -}}

{{- define "common.security.capabilities" -}}
capabilities:
  drop:
    - ALL
{{- end -}}

{{- define "common.security.podContext" -}}
{{-   $defaults := dict "fsGroup" 1000 -}}
{{-   $custom := .Values.podSecurityContext | default dict -}}
{{-   mergeOverwrite $defaults $custom | toYaml -}}
{{- end -}}
