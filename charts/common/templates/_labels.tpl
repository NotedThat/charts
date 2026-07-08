{{/*
Kubernetes standard labels
*/}}
{{- define "common.labels.standard" -}}
helm.sh/chart: {{ include "common.names.chart" . }}
{{ include "common.labels.matchLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) }}
{{- end }}
{{- end -}}

{{/*
Labels used on, e.g., Deployments' spec.selector.matchLabels and Services' spec.selector
*/}}
{{- define "common.labels.matchLabels" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
