{{/*
Convert a camelCase or hyphenated field name to an UPPER_SNAKE_CASE environment variable name.
Usage:
{{ include "common.utils.fieldToEnvVar" (dict "field" "my-password") }}
*/}}
{{- define "common.utils.fieldToEnvVar" -}}
{{- .field | upper | replace "-" "_" | replace "." "_" -}}
{{- end -}}

{{/*
Gets a value from .Values given a path string.
Usage:
{{ include "common.utils.getValueFromKey" (dict "key" "path.to.key" "context" $) }}
*/}}
{{- define "common.utils.getValueFromKey" -}}
{{- $splitKey := splitList "." .key -}}
{{- $value := .context.Values -}}
{{- range $splitKey -}}
  {{- if not $value -}}
    {{- printf "." -}}
  {{- else if eq (typeOf $value) "map[string]interface {}" -}}
    {{- $value = index $value . -}}
  {{- end -}}
{{- end -}}
{{- if $value -}}
  {{- $value | toString -}}
{{- end -}}
{{- end -}}

{{/*
Returns first .Values key with a defined value.
Usage:
{{ include "common.utils.getKeyFromList" (dict "keys" (list "path.to.key1" "path.to.key2") "context" $) }}
*/}}
{{- define "common.utils.getKeyFromList" -}}
{{- range .keys -}}
  {{- $value := include "common.utils.getValueFromKey" (dict "key" . "context" $.context) }}
  {{- if $value -}}
    {{- $value -}}
    {{- break -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Checksum a template at a given path.
Usage:
{{ include "common.utils.checksumTemplate" (dict "path" "/configmap.yaml" "context" $) }}
*/}}
{{- define "common.utils.checksumTemplate" -}}
{{- include .path .context | sha256sum -}}
{{- end -}}

{{/*
Retrieve a secret value, looking up from an existing secret first.
Usage:
{{ include "common.utils.secret.getvalue" (dict "secret" "my-secret" "field" "password" "context" $) }}
*/}}
{{- define "common.utils.secret.getvalue" -}}
{{- $obj := (lookup "v1" "Secret" .context.Release.Namespace .secret) | default dict -}}
{{- $data := ($obj.data) | default dict -}}
{{- $value := index $data .field -}}
{{- if $value -}}
  {{- $value | b64dec -}}
{{- end -}}
{{- end -}}
