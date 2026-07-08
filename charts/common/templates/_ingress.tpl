{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "common.ingress.apiVersion" -}}
{{- include "common.capabilities.ingress.apiVersion" . -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations.
Usage:
{{ include "common.ingress.certManagerRequest" (dict "annotations" .Values.ingress.annotations) }}
*/}}
{{- define "common.ingress.certManagerRequest" -}}
{{- if or (hasKey .annotations "cert-manager.io/cluster-issuer") (hasKey .annotations "cert-manager.io/issuer") (hasKey .annotations "kubernetes.io/tls-acme") -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if the ingress API supports pathType (networking.k8s.io/v1+).
Always true for K8s 1.28+.
*/}}
{{- define "common.ingress.supportsPathType" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1" -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if the ingress API supports ingressClassName field (networking.k8s.io/v1+).
Always true for K8s 1.28+.
*/}}
{{- define "common.ingress.supportsIngressClassname" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1" -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Render an ingress backend service block for networking.k8s.io/v1.
Usage:
{{ include "common.ingress.backend" (dict "serviceName" "my-svc" "servicePort" "http") }}
*/}}
{{- define "common.ingress.backend" -}}
service:
  name: {{ .serviceName }}
  port:
    {{- if typeIs "string" .servicePort }}
    name: {{ .servicePort }}
    {{- else }}
    number: {{ .servicePort }}
    {{- end }}
{{- end -}}
