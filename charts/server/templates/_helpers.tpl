{{/*
Expand the name of the chart.
*/}}
{{- define "server.names.name" -}}
{{- include "common.names.name" . -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "server.names.fullname" -}}
{{- include "common.names.fullname" . -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden.
*/}}
{{- define "server.names.namespace" -}}
{{- include "common.names.namespace" . -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "server.names.chart" -}}
{{- include "common.names.chart" . -}}
{{- end -}}

{{/*
Kubernetes standard labels.
*/}}
{{- define "server.labels.standard" -}}
{{- include "common.labels.standard" . -}}
{{- end -}}

{{/*
Labels used on selector.matchLabels and Service spec.selector.
*/}}
{{- define "server.labels.matchLabels" -}}
{{- include "common.labels.matchLabels" . -}}
{{- end -}}

{{/*
Return the proper image name.
Empty image.tag falls back to Chart.appVersion so releases stay in lockstep.
Usage: {{ include "server.image" . }}
*/}}
{{- define "server.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) -}}
{{- end -}}

{{/*
Return the ServiceAccount name to use.
Usage: {{ include "server.serviceAccountName" . }}
*/}}
{{- define "server.serviceAccountName" -}}
{{- include "common.rbac.serviceAccountName" (dict "serviceAccount" .Values.serviceAccount "context" $) -}}
{{- end -}}
