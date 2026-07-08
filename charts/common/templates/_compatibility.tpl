{{/*
Returns true if the cluster is running on OpenShift
*/}}
{{- define "common.compatibility.isOpenshift" -}}
{{- if .Capabilities.APIVersions.Has "security.openshift.io/v1" -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Render a security context, omitting fsGroup on OpenShift (which manages it automatically).
Usage:
{{ include "common.compatibility.renderSecurityContext" (dict "secContext" .Values.podSecurityContext "context" $) }}
*/}}
{{- define "common.compatibility.renderSecurityContext" -}}
{{- $adaptedContext := .secContext -}}
{{- if include "common.compatibility.isOpenshift" .context -}}
  {{- $adaptedContext = omit $adaptedContext "fsGroup" "runAsUser" -}}
{{- end -}}
{{- if $adaptedContext -}}
  {{- toYaml $adaptedContext -}}
{{- end -}}
{{- end -}}
