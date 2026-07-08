{{/*
Return the proper image name.

Resolution order for the image reference:
  1. `imageRoot.digest` (rendered as `repo@digest`).
  2. `imageRoot.tag` (rendered as `repo:tag`).
  3. `chart.AppVersion` if `chart` is supplied and `tag` is empty
     (rendered as `repo:appVersion`).
  4. Empty string (legacy behavior — emits `repo:`).

Passing `chart` lets a consumer chart default `image.tag` to `""` in its
values.yaml and have every release of the chart pin to the matching image
tag automatically, as long as release tooling (e.g. release-please) keeps
`Chart.yaml`'s `appVersion` in lockstep with the published image.

Usage:
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
*/}}
{{- define "common.images.image" -}}
{{- $registryName := .imageRoot.registry -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}
{{- if .global }}
    {{- if .global.imageRegistry }}
     {{- $registryName = .global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- else if and (not .imageRoot.tag) .chart -}}
    {{- $termination = .chart.AppVersion | toString -}}
{{- end -}}
{{- if $registryName }}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s" $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names evaluating values as templates.
Usage:
{{ include "common.images.renderPullSecrets" (dict "images" (list .Values.path.to.the.image1, .Values.path.to.the.image2) "context" $) }}
*/}}
{{- define "common.images.renderPullSecrets" -}}
  {{- $pullSecrets := list -}}
  {{- $context := .context -}}

  {{- if $context.Values.global -}}
    {{- range $context.Values.global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets (include "common.tplvalues.render" (dict "value" . "context" $context)) -}}
    {{- end -}}
  {{- end -}}
  {{- range .images -}}
    {{- range .pullSecrets -}}
      {{- $pullSecrets = append $pullSecrets (include "common.tplvalues.render" (dict "value" . "context" $context)) -}}
    {{- end -}}
  {{- end -}}
  {{- if (not (empty $pullSecrets)) -}}
imagePullSecrets:
    {{- range (uniq $pullSecrets) }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Return the list of image pull secrets (as a list, not rendered YAML).
Usage:
{{ include "common.images.pullSecrets" (dict "images" (list .Values.path.to.the.image1) "global" .Values.global) }}
*/}}
{{- define "common.images.pullSecrets" -}}
  {{- $pullSecrets := list -}}
  {{- if .global -}}
    {{- range .global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}
  {{- range .images -}}
    {{- range .pullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}
  {{- if (not (empty $pullSecrets)) -}}
    {{- uniq $pullSecrets | toJson -}}
  {{- end -}}
{{- end -}}

{{/*
Return the proper image version (tag or digest).
Usage:
{{ include "common.images.version" (dict "imageRoot" .Values.path.to.the.image "chart" .Chart) }}
*/}}
{{- define "common.images.version" -}}
{{- if .imageRoot.digest -}}
    {{- .imageRoot.digest -}}
{{- else if .imageRoot.tag -}}
    {{- .imageRoot.tag | toString -}}
{{- else -}}
    {{- .chart.AppVersion -}}
{{- end -}}
{{- end -}}
