{{- define "common.resources" -}}
{{-   $defaultRequests := dict "cpu" "100m" "memory" "128Mi" -}}
{{-   $defaultLimits := dict "cpu" "500m" "memory" "512Mi" -}}
{{-   $requests := mergeOverwrite $defaultRequests (.Values.resources.requests | default dict) -}}
{{-   $limits := mergeOverwrite $defaultLimits (.Values.resources.limits | default dict) -}}
requests: {{ toYaml $requests | nindent 2 }}
limits: {{ toYaml $limits | nindent 2 }}
{{- end -}}
