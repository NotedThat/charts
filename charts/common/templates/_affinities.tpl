{{/*
Return a soft nodeAffinity definition
Usage:
{{ include "common.affinities.nodes.soft" (dict "key" "FOO" "values" (list "BAR" "BAZ")) }}
*/}}
{{- define "common.affinities.nodes.soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - preference:
      matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
    weight: 1
{{- end -}}

{{/*
Return a hard nodeAffinity definition
Usage:
{{ include "common.affinities.nodes.hard" (dict "key" "FOO" "values" (list "BAR" "BAZ")) }}
*/}}
{{- define "common.affinities.nodes.hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
{{- end -}}

{{/*
Return a soft podAffinity/podAntiAffinity definition
Usage:
{{ include "common.affinities.pods.soft" (dict "component" "FOO" "customLabels" .Values.podLabels "topologyKey" "kubernetes.io/hostname" "context" $) }}
*/}}
{{- define "common.affinities.pods.soft" -}}
{{- $component := default "" .component -}}
{{- $customLabels := default (dict) .customLabels -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "common.labels.matchLabels" .context) | nindent 10 }}
          {{- if not (empty $component) }}
          app.kubernetes.io/component: {{ $component }}
          {{- end }}
          {{- range $key, $value := $customLabels }}
          {{ $key }}: {{ $value | quote }}
          {{- end }}
      topologyKey: {{ default "kubernetes.io/hostname" .topologyKey }}
    weight: 1
{{- end -}}

{{/*
Return a hard podAffinity/podAntiAffinity definition
Usage:
{{ include "common.affinities.pods.hard" (dict "component" "FOO" "customLabels" .Values.podLabels "topologyKey" "kubernetes.io/hostname" "context" $) }}
*/}}
{{- define "common.affinities.pods.hard" -}}
{{- $component := default "" .component -}}
{{- $customLabels := default (dict) .customLabels -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels: {{- (include "common.labels.matchLabels" .context) | nindent 8 }}
        {{- if not (empty $component) }}
        app.kubernetes.io/component: {{ $component }}
        {{- end }}
        {{- range $key, $value := $customLabels }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
    topologyKey: {{ default "kubernetes.io/hostname" .topologyKey }}
{{- end -}}

{{/*
Render tolerations from values.
Usage:
{{ include "common.affinities.tolerations.render" .Values.tolerations }}
*/}}
{{- define "common.affinities.tolerations.render" -}}
{{- if . -}}
tolerations: {{- toYaml . | nindent 2 }}
{{- end -}}
{{- end -}}
