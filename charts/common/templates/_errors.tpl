{{/*
Fail if passwords are empty on upgrade.
Usage:
{{ include "common.errors.upgrade.passwords.empty" (dict "validationErrors" (list $error1 $error2) "context" $) }}
*/}}
{{- define "common.errors.upgrade.passwords.empty" -}}
  {{- if .validationErrors -}}
    {{- $errorString := "\nPASSWORDS ERROR: You must provide your current passwords when upgrading the release.\n" -}}
    {{- $errorString = print $errorString "                 Note that even after reinstallation, old credentials may be needed as they may be kept in persistent volume claims.\n" -}}
    {{- $errorString = print $errorString "                 Further information can be obtained at https://docs.bitnami.com/general/how-to/troubleshoot-helm-chart-issues/#credential-errors-while-upgrading-chart-releases\n" -}}
    {{- $errorString = print $errorString "\n" -}}
    {{- range .validationErrors -}}
      {{- $errorString = print $errorString "\t- " . "\n" -}}
    {{- end -}}
    {{- fail $errorString -}}
  {{- end -}}
{{- end -}}

{{/*
Fail if images use insecure (HTTP) registries.
Usage:
{{ include "common.errors.insecureImages" (dict "images" (list .Values.image) "context" $) }}
*/}}
{{- define "common.errors.insecureImages" -}}
  {{- $insecureImages := list -}}
  {{- range .images -}}
    {{- if and .registry (hasPrefix "http://" .registry) -}}
      {{- $insecureImages = append $insecureImages (printf "%s/%s:%s" .registry .repository (default "latest" (.tag | toString))) -}}
    {{- end -}}
  {{- end -}}
  {{- if $insecureImages -}}
    {{- fail (printf "\nINSECURE IMAGES ERROR: The following images use insecure HTTP registries:\n%s\nPlease use HTTPS registries only." (join "\n" $insecureImages)) -}}
  {{- end -}}
{{- end -}}

{{/*
Validate a single required value is not empty.
Usage:
{{ include "common.validations.values.single.empty" (dict "valueKey" "path.to.value" "secret" "my-secret" "field" "password" "subchart" "" "context" $) }}
*/}}
{{- define "common.validations.values.single.empty" -}}
  {{- $value := include "common.utils.getValueFromKey" (dict "key" .valueKey "context" .context) -}}
  {{- $secret := (lookup "v1" "Secret" .context.Release.Namespace .secret) -}}
  {{- if not $value -}}
    {{- if not $secret -}}
      {{- printf "\n    '%s' must not be empty, please add '--set %s=<value>'" .valueKey .valueKey -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Validate multiple required values are not empty.
Usage:
{{ include "common.validations.values.multiple.empty" (dict "required" (list (dict "valueKey" "path.to.value" "secret" "my-secret" "field" "password")) "context" $) }}
*/}}
{{- define "common.validations.values.multiple.empty" -}}
  {{- range .required -}}
    {{- include "common.validations.values.single.empty" (dict "valueKey" .valueKey "secret" .secret "field" .field "subchart" (default "" .subchart) "context" $.context) -}}
  {{- end -}}
{{- end -}}
