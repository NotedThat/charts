{{/*
Warning about using rolling tag.
Usage:
{{ include "common.warnings.rollingTag" .Values.path.to.the.imageRoot }}
*/}}
{{- define "common.warnings.rollingTag" -}}
{{- if and (contains "." .repository) (not (.tag | toString | regexMatch "^[0-9]+\\.[0-9]+")) }}
WARNING: Rolling tag detected ({{ .repository }}:{{ .tag }}), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://docs.bitnami.com/tutorials/understand-rolling-tags-containers
{{- end }}
{{- end -}}

{{/*
Warning about replaced images from the default values.
Usage:
{{ include "common.warnings.modifiedImages" (dict "images" (list .Values.image) "context" $) }}
*/}}
{{- define "common.warnings.modifiedImages" -}}
{{- $warnings := list -}}
{{- range .images -}}
  {{- if and .repository (not (contains "bitnami" .repository)) -}}
    {{- $warnings = append $warnings (printf "Image %s/%s:%s is not a Bitnami image. Be aware that Bitnami support won't cover issues with non-Bitnami images." (default "" .registry) .repository (default "" (.tag | toString))) -}}
  {{- end -}}
{{- end -}}
{{- if $warnings -}}
  {{- printf "\nWARNINGS:\n" -}}
  {{- range $warnings -}}
    {{- printf "  - %s\n" . -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Warning about missing resource limits/requests.
Usage:
{{ include "common.warnings.resources" (dict "sections" (list "section1" "section2") "context" $) }}
*/}}
{{- define "common.warnings.resources" -}}
{{- $warnings := list -}}
{{- range .sections -}}
  {{- $section := include "common.utils.getValueFromKey" (dict "key" . "context" $.context) | fromYaml -}}
  {{- if and $section (not $section.limits) (not $section.requests) -}}
    {{- $warnings = append $warnings (printf "No resource limits/requests set for section '%s'. Consider setting them to avoid resource contention." .) -}}
  {{- end -}}
{{- end -}}
{{- if $warnings -}}
  {{- printf "\nWARNINGS:\n" -}}
  {{- range $warnings -}}
    {{- printf "  - %s\n" . -}}
  {{- end -}}
{{- end -}}
{{- end -}}
