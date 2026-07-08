{{/*
Return a resource preset object.
Usage:
{{ include "common.resources.preset" (dict "type" "small") }}
*/}}
{{- define "common.resources.preset" -}}
{{- $presets := dict
  "nano" (dict
    "requests" (dict "cpu" "100m" "memory" "128Mi" "ephemeral-storage" "50Mi")
    "limits" (dict "cpu" "150m" "memory" "192Mi" "ephemeral-storage" "2Gi"))
  "micro" (dict
    "requests" (dict "cpu" "250m" "memory" "256Mi" "ephemeral-storage" "50Mi")
    "limits" (dict "cpu" "500m" "memory" "512Mi" "ephemeral-storage" "2Gi"))
  "small" (dict
    "requests" (dict "cpu" "500m" "memory" "512Mi" "ephemeral-storage" "50Mi")
    "limits" (dict "cpu" "750m" "memory" "768Mi" "ephemeral-storage" "2Gi"))
  "medium" (dict
    "requests" (dict "cpu" "500m" "memory" "512Mi" "ephemeral-storage" "50Mi")
    "limits" (dict "cpu" "1000m" "memory" "1Gi" "ephemeral-storage" "2Gi"))
  "large" (dict
    "requests" (dict "cpu" "1000m" "memory" "1Gi" "ephemeral-storage" "50Mi")
    "limits" (dict "cpu" "2000m" "memory" "2Gi" "ephemeral-storage" "2Gi"))
  "xlarge" (dict
    "requests" (dict "cpu" "1000m" "memory" "2Gi" "ephemeral-storage" "50Mi")
    "limits" (dict "cpu" "3000m" "memory" "3Gi" "ephemeral-storage" "2Gi"))
  "2xlarge" (dict
    "requests" (dict "cpu" "2000m" "memory" "4Gi" "ephemeral-storage" "50Mi")
    "limits" (dict "cpu" "4000m" "memory" "6Gi" "ephemeral-storage" "2Gi"))
-}}
{{- if hasKey $presets .type -}}
  {{- index $presets .type | toYaml -}}
{{- else -}}
  {{- fail (printf "ERROR: Preset key '%s' invalid. Allowed values are %s" .type (join "," (keys $presets))) -}}
{{- end -}}
{{- end -}}

{{/*
Apply a resource preset with optional user overrides.
User-provided values take precedence over preset values.
Usage:
{{ include "common.resources.preset.apply" (dict "type" "small" "resources" .Values.resources) }}
*/}}
{{- define "common.resources.preset.apply" -}}
{{- $preset := include "common.resources.preset" (dict "type" .type) | fromYaml -}}
{{- if .resources -}}
  {{- toYaml (mergeOverwrite $preset .resources) -}}
{{- else -}}
  {{- toYaml $preset -}}
{{- end -}}
{{- end -}}
