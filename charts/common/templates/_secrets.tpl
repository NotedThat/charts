{{/*
Generate secret name.
Usage:
{{ include "common.secrets.name" (dict "existingSecret" .Values.existingSecret "defaultNameSuffix" "foo" "context" $) }}
*/}}
{{- define "common.secrets.name" -}}
{{- if .existingSecret -}}
  {{- if not (typeIs "string" .existingSecret) -}}
    {{- if .existingSecret.name -}}
      {{- .existingSecret.name -}}
    {{- else -}}
      {{- include "common.names.fullname" .context -}}{{- if .defaultNameSuffix -}}-{{ .defaultNameSuffix | lower }}{{- end -}}
    {{- end -}}
  {{- else -}}
    {{- .existingSecret -}}
  {{- end -}}
{{- else -}}
  {{- include "common.names.fullname" .context -}}{{- if .defaultNameSuffix -}}-{{ .defaultNameSuffix | lower }}{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate secret key.
Usage:
{{ include "common.secrets.key" (dict "existingSecret" .Values.existingSecret "key" "keyName") }}
*/}}
{{- define "common.secrets.key" -}}
{{- $key := .key -}}
{{- if .existingSecret -}}
  {{- if not (typeIs "string" .existingSecret) -}}
    {{- if (index .existingSecret .key) -}}
      {{- index .existingSecret .key -}}
    {{- else -}}
      {{- $key -}}
    {{- end -}}
  {{- else -}}
    {{- $key -}}
  {{- end -}}
{{- else -}}
  {{- $key -}}
{{- end -}}
{{- end -}}

{{/*
Manage a secret password. If the secret already exists in the cluster, reuse it.
Otherwise use the provided value or generate a random one.
Usage:
{{ include "common.secrets.passwords.manage" (dict "secret" "my-secret" "key" "password" "providedValues" (list "path.to.value") "length" 10 "strong" false "chartName" "myChart" "context" $) }}
*/}}
{{- define "common.secrets.passwords.manage" -}}
{{- $password := "" -}}
{{- $subchart := "" -}}
{{- $chartName := default "" .chartName -}}
{{- $passwordLength := default 10 .length -}}
{{- $providedPasswordKey := include "common.utils.getKeyFromList" (dict "keys" .providedValues "context" .context) -}}
{{- $providedPasswordValue := include "common.utils.getValueFromKey" (dict "key" $providedPasswordKey "context" .context) -}}
{{- $secretData := (lookup "v1" "Secret" .context.Release.Namespace .secret).data -}}
{{- if $secretData -}}
  {{- if index $secretData .key -}}
    {{- $password = index $secretData .key | b64dec -}}
  {{- else if $providedPasswordValue -}}
    {{- $password = $providedPasswordValue -}}
  {{- else -}}
    {{- $password = randAlphaNum $passwordLength -}}
  {{- end -}}
{{- else if $providedPasswordValue -}}
  {{- $password = $providedPasswordValue -}}
{{- else -}}
  {{- $password = randAlphaNum $passwordLength -}}
{{- end -}}
{{- $password | b64enc | quote -}}
{{- end -}}

{{/*
Returns whether a previous generated secret already exists.
Usage:
{{ include "common.secrets.exists" (dict "secret" "my-secret" "context" $) }}
*/}}
{{- define "common.secrets.exists" -}}
{{- $secret := (lookup "v1" "Secret" .context.Release.Namespace .secret) -}}
{{- if $secret -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Lookup a secret key value.
Usage:
{{ include "common.secrets.lookup" (dict "secret" "my-secret" "key" "password" "defaultValue" .Values.password "context" $) }}
*/}}
{{- define "common.secrets.lookup" -}}
{{- $value := "" -}}
{{- $secretData := (lookup "v1" "Secret" .context.Release.Namespace .secret).data -}}
{{- if and $secretData (index $secretData .key) -}}
  {{- $value = index $secretData .key | b64dec -}}
{{- else if .defaultValue -}}
  {{- $value = .defaultValue -}}
{{- end -}}
{{- if $value -}}
  {{- $value | b64enc | quote -}}
{{- end -}}
{{- end -}}
