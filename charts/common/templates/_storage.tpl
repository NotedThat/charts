{{/*
Return the proper Storage Class
Usage:
{{ include "common.storage.class" (dict "persistence" .Values.persistence "global" $) }}
*/}}
{{- define "common.storage.class" -}}
{{- $storageClass := ((.persistence).storageClass) -}}
{{- if (.global).storageClass -}}
  {{- $storageClass = .global.storageClass -}}
{{- end -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
    {{- printf "storageClassName: \"\"" -}}
  {{- else -}}
    {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}
