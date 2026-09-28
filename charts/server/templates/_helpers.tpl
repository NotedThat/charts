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

{{/*
Stringify a value for an env var. YAML numbers arrive as float64, which would
print 104857600 as 1.048576e+08, so whole numbers are printed as integers.
Usage: {{ include "server.envValue" .Values.embedding.dimensions }}
*/}}
{{- define "server.envValue" -}}
{{- if kindIs "float64" . -}}
{{- if eq . (floor .) -}}{{- printf "%d" (int64 .) -}}{{- else -}}{{- . -}}{{- end -}}
{{- else if kindIs "slice" . -}}
{{- join "," . -}}
{{- else if not (kindIs "invalid" .) -}}
{{- toString . -}}
{{- end -}}
{{- end -}}

{{/*
A plain env var, rendered only when the value is set. The server treats an
empty variable as supplied, so an unset setting must not appear at all.
Usage: {{ include "server.envIfSet" (dict "name" "NOTEDTHAT_X" "value" .Values.x) }}
*/}}
{{- define "server.envIfSet" -}}
{{- $value := include "server.envValue" .value -}}
{{- if $value }}
- name: {{ .name }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Name of the chart-managed Secret holding inline credentials.
*/}}
{{- define "server.secretName" -}}
{{- include "server.names.fullname" . -}}
{{- end -}}

{{/*
An env var read from a Secret: the block's existingSecret when set, otherwise
the chart-managed Secret under the chart's key.
Usage: {{ include "server.secretEnv" (dict "name" "NOTEDTHAT_API_TOKEN" "existingSecret" .Values.auth.existingSecret "existingKey" .Values.auth.secretKeys.apiToken "key" "api-token" "context" $) }}
*/}}
{{- define "server.secretEnv" -}}
- name: {{ .name }}
  valueFrom:
    secretKeyRef:
      {{- if .existingSecret }}
      name: {{ tpl .existingSecret .context }}
      key: {{ .existingKey }}
      {{- else }}
      name: {{ include "server.secretName" .context }}
      key: {{ .key }}
      {{- end }}
{{- end -}}

{{/*
The public base URL of the ingress, or empty when the ingress is disabled.
*/}}
{{- define "server.ingressUrl" -}}
{{- if .Values.ingress.enabled -}}
{{- printf "%s://%s" (ternary "https" "http" (and .Values.ingress.tls true)) .Values.ingress.hostname -}}
{{- end -}}
{{- end -}}

{{/*
Chart-managed Secret data: only the credentials given inline, for blocks that
do not name an existingSecret.
*/}}
{{- define "server.secretData" -}}
{{- $v := .Values -}}
{{- if not $v.auth.existingSecret }}
api-token: {{ $v.auth.apiToken | b64enc | quote }}
webdav-username: {{ $v.auth.webdav.username | b64enc | quote }}
webdav-password: {{ $v.auth.webdav.password | b64enc | quote }}
{{- end }}
{{- if not $v.s3.existingSecret }}
s3-access-key-id: {{ $v.s3.accessKeyId | b64enc | quote }}
s3-secret-access-key: {{ $v.s3.secretAccessKey | b64enc | quote }}
{{- end }}
{{- if and $v.qdrant.apiKey (not $v.qdrant.existingSecret) }}
qdrant-api-key: {{ $v.qdrant.apiKey | b64enc | quote }}
{{- end }}
{{- if not $v.embedding.existingSecret }}
embedding-api-key: {{ $v.embedding.apiKey | b64enc | quote }}
{{- end }}
{{- if and (eq $v.events.backend "nats") (not $v.events.nats.existingSecret) }}
nats-url: {{ $v.events.nats.url | b64enc | quote }}
{{- end }}
{{- end -}}

{{/*
Container environment for the server.
*/}}
{{- define "server.env" -}}
{{- $v := .Values -}}
- name: NOTEDTHAT_LISTEN_ADDR
  value: {{ printf "0.0.0.0:%v" $v.containerPorts.http | quote }}
- name: NOTEDTHAT_UPLOAD_TMP_DIR
  value: {{ $v.staging.mountPath | quote }}
{{- include "server.secretEnv" (dict "name" "NOTEDTHAT_API_TOKEN" "existingSecret" $v.auth.existingSecret "existingKey" $v.auth.secretKeys.apiToken "key" "api-token" "context" .) | nindent 0 }}
{{- include "server.secretEnv" (dict "name" "NOTEDTHAT_WEBDAV_USERNAME" "existingSecret" $v.auth.existingSecret "existingKey" $v.auth.secretKeys.webdavUsername "key" "webdav-username" "context" .) | nindent 0 }}
{{- include "server.secretEnv" (dict "name" "NOTEDTHAT_WEBDAV_PASSWORD" "existingSecret" $v.auth.existingSecret "existingKey" $v.auth.secretKeys.webdavPassword "key" "webdav-password" "context" .) | nindent 0 }}
- name: NOTEDTHAT_KBS
  value: {{ join "," $v.knowledgebases | quote }}
{{- /* Storage: s3 */}}
- name: NOTEDTHAT_STORAGE_BACKEND
  value: "s3"
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_S3_REGION" "value" $v.s3.region) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_S3_ENDPOINT_URL" "value" $v.s3.endpointUrl) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_S3_FORCE_PATH_STYLE" "value" $v.s3.forcePathStyle) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_S3_RECONCILE" "value" $v.s3.reconcile) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_S3_ALLOW_UNENFORCED_CONDITIONAL_WRITES" "value" $v.s3.allowUnenforcedConditionalWrites) }}
{{- include "server.secretEnv" (dict "name" "NOTEDTHAT_S3_ACCESS_KEY_ID" "existingSecret" $v.s3.existingSecret "existingKey" $v.s3.secretKeys.accessKeyId "key" "s3-access-key-id" "context" .) | nindent 0 }}
{{- include "server.secretEnv" (dict "name" "NOTEDTHAT_S3_SECRET_ACCESS_KEY" "existingSecret" $v.s3.existingSecret "existingKey" $v.s3.secretKeys.secretAccessKey "key" "s3-secret-access-key" "context" .) | nindent 0 }}
{{- /* Qdrant */}}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_QDRANT_URL" "value" $v.qdrant.url) }}
{{- if or $v.qdrant.apiKey $v.qdrant.existingSecret }}
{{- include "server.secretEnv" (dict "name" "NOTEDTHAT_QDRANT_API_KEY" "existingSecret" $v.qdrant.existingSecret "existingKey" $v.qdrant.secretKeys.apiKey "key" "qdrant-api-key" "context" .) | nindent 0 }}
{{- end }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_QDRANT_TIMEOUT_MS" "value" $v.qdrant.timeoutMs) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_QDRANT_CONNECT_TIMEOUT_MS" "value" $v.qdrant.connectTimeoutMs) }}
{{- /* Embedding */}}
{{- include "server.envIfSet" (dict "name" "EMBEDDING_ENDPOINT_URL" "value" $v.embedding.endpointUrl) }}
{{- include "server.envIfSet" (dict "name" "EMBEDDING_MODEL" "value" $v.embedding.model) }}
{{- include "server.envIfSet" (dict "name" "EMBEDDING_DIMENSIONS" "value" $v.embedding.dimensions) }}
{{- include "server.secretEnv" (dict "name" "EMBEDDING_API_KEY" "existingSecret" $v.embedding.existingSecret "existingKey" $v.embedding.secretKeys.apiKey "key" "embedding-api-key" "context" .) | nindent 0 }}
{{- include "server.envIfSet" (dict "name" "EMBEDDING_BATCH_SIZE" "value" $v.embedding.batchSize) }}
{{- include "server.envIfSet" (dict "name" "EMBEDDING_TIMEOUT_MS" "value" $v.embedding.timeoutMs) }}
{{- include "server.envIfSet" (dict "name" "EMBEDDING_MAX_RETRIES" "value" $v.embedding.maxRetries) }}
{{- include "server.envIfSet" (dict "name" "EMBEDDING_MAX_INPUT_TOKENS" "value" $v.embedding.maxInputTokens) }}
{{- /* OIDC */}}
{{- if $v.oidc.issuer }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_OIDC_ISSUER" "value" $v.oidc.issuer) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_OIDC_AUDIENCE" "value" $v.oidc.audience) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_OIDC_USERNAME_CLAIM" "value" $v.oidc.usernameClaim) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_OIDC_GROUPS_CLAIM" "value" $v.oidc.groupsClaim) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_OIDC_HTTP_TIMEOUT_MS" "value" $v.oidc.httpTimeoutMs) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_OIDC_RESOURCE" "value" ($v.oidc.resource | default (include "server.ingressUrl" .))) }}
{{- if or $v.oidc.caCert.existingConfigMap $v.oidc.caCert.existingSecret }}
- name: NOTEDTHAT_OIDC_CA_CERT
  value: "/etc/notedthat/oidc/ca.pem"
{{- end }}
{{- end }}
{{- /* Events */}}
- name: NOTEDTHAT_EVENTS_BACKEND
  value: {{ $v.events.backend | quote }}
{{- if eq $v.events.backend "memory" }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_EVENTS_MEMORY_CAPACITY" "value" $v.events.memoryCapacity) }}
{{- else if eq $v.events.backend "nats" }}
{{- include "server.secretEnv" (dict "name" "NOTEDTHAT_NATS_URL" "existingSecret" $v.events.nats.existingSecret "existingKey" $v.events.nats.secretKeys.url "key" "nats-url" "context" .) | nindent 0 }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_NATS_STREAM" "value" $v.events.nats.stream) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_NATS_MAX_AGE_SECS" "value" $v.events.nats.maxAgeSecs) }}
{{- end }}
{{- /* MCP */}}
{{- $mcpHosts := $v.mcp.allowedHosts -}}
{{- if and (not $mcpHosts) $v.ingress.enabled -}}{{- $mcpHosts = list $v.ingress.hostname -}}{{- end -}}
{{- $mcpOrigins := $v.mcp.allowedOrigins -}}
{{- if and (not $mcpOrigins) $v.ingress.enabled -}}{{- $mcpOrigins = list (include "server.ingressUrl" .) -}}{{- end -}}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_MCP_HTTP_ALLOWED_HOSTS" "value" $mcpHosts) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_MCP_HTTP_ALLOWED_ORIGINS" "value" $mcpOrigins) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_MCP_ANONYMOUS" "value" $v.mcp.anonymous) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_MCP_MAX_SESSIONS" "value" $v.mcp.maxSessions) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_MCP_MAX_READ_BYTES" "value" $v.mcp.maxReadBytes) }}
{{- /* Metrics: a second listener, off unless enabled */}}
{{- if $v.metrics.enabled }}
- name: NOTEDTHAT_METRICS_ENABLED
  value: "true"
- name: NOTEDTHAT_METRICS_LISTEN_ADDR
  value: {{ printf "0.0.0.0:%v" $v.containerPorts.metrics | quote }}
{{- end }}
{{- /* Server tuning */}}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_LOG_FORMAT" "value" $v.server.logFormat) }}
{{- include "server.envIfSet" (dict "name" "RUST_LOG" "value" $v.server.rustLog) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_MAX_PATCHABLE_SIZE" "value" $v.server.maxPatchableSize) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_REQUEST_TIMEOUT_MS" "value" $v.server.requestTimeoutMs) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_WEBDAV_REQUEST_TIMEOUT_MS" "value" $v.server.webdavRequestTimeoutMs) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_MAX_REQUESTS_IN_FLIGHT" "value" $v.server.maxRequestsInFlight) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_HEADER_READ_TIMEOUT_MS" "value" $v.server.headerReadTimeoutMs) }}
{{- include "server.envIfSet" (dict "name" "NOTEDTHAT_READY_PROBE_INTERVAL_MS" "value" $v.server.readyProbeIntervalMs) }}
{{- end -}}

{{/*
Fail rendering on configuration the server would refuse at startup.
*/}}
{{- define "server.validateValues" -}}
{{- $v := .Values -}}
{{- $errors := list -}}
{{- if not $v.auth.existingSecret -}}
  {{- if not $v.auth.apiToken -}}{{- $errors = append $errors "auth.apiToken is required (or set auth.existingSecret)" -}}{{- end -}}
  {{- if not $v.auth.webdav.username -}}{{- $errors = append $errors "auth.webdav.username is required (or set auth.existingSecret)" -}}{{- end -}}
  {{- if not $v.auth.webdav.password -}}{{- $errors = append $errors "auth.webdav.password is required (or set auth.existingSecret)" -}}{{- end -}}
{{- end -}}
{{- if not $v.knowledgebases -}}
  {{- $errors = append $errors "knowledgebases must list at least one slug" -}}
{{- end -}}
{{- range $v.knowledgebases -}}
  {{- if not (regexMatch "^[a-z0-9-]{1,40}$" (toString .)) -}}
    {{- $errors = append $errors (printf "knowledgebases: %q must match [a-z0-9-]{1,40}" (toString .)) -}}
  {{- end -}}
{{- end -}}
{{- if ne (len $v.knowledgebases) (len (uniq $v.knowledgebases)) -}}
  {{- $errors = append $errors "knowledgebases must not contain duplicates" -}}
{{- end -}}
{{- if not $v.s3.region -}}{{- $errors = append $errors "s3.region is required" -}}{{- end -}}
{{- if and (not $v.s3.existingSecret) (not (and $v.s3.accessKeyId $v.s3.secretAccessKey)) -}}
  {{- $errors = append $errors "s3.accessKeyId and s3.secretAccessKey are required (or set s3.existingSecret)" -}}
{{- end -}}
{{- if not $v.qdrant.url -}}{{- $errors = append $errors "qdrant.url is required" -}}{{- end -}}
{{- if not $v.embedding.endpointUrl -}}{{- $errors = append $errors "embedding.endpointUrl is required" -}}{{- end -}}
{{- if not $v.embedding.model -}}{{- $errors = append $errors "embedding.model is required" -}}{{- end -}}
{{- if not (include "server.envValue" $v.embedding.dimensions) -}}{{- $errors = append $errors "embedding.dimensions is required" -}}{{- end -}}
{{- if and (not $v.embedding.existingSecret) (not $v.embedding.apiKey) -}}
  {{- $errors = append $errors "embedding.apiKey is required (or set embedding.existingSecret)" -}}
{{- end -}}
{{- if $v.oidc.issuer -}}
  {{- if not $v.oidc.audience -}}{{- $errors = append $errors "oidc.audience is required when oidc.issuer is set" -}}{{- end -}}
  {{- if and $v.oidc.caCert.existingConfigMap $v.oidc.caCert.existingSecret -}}
    {{- $errors = append $errors "oidc.caCert: set existingConfigMap or existingSecret, not both" -}}
  {{- end -}}
{{- else if or $v.oidc.audience $v.oidc.usernameClaim $v.oidc.groupsClaim $v.oidc.httpTimeoutMs $v.oidc.resource $v.oidc.caCert.existingConfigMap $v.oidc.caCert.existingSecret -}}
  {{- $errors = append $errors "oidc.* is set but oidc.issuer is empty; the server refuses OIDC settings without an issuer" -}}
{{- end -}}
{{- if not (has $v.events.backend (list "none" "memory" "nats")) -}}
  {{- $errors = append $errors (printf "events.backend must be none, memory or nats, got %q" (toString $v.events.backend)) -}}
{{- end -}}
{{- if and (eq $v.events.backend "nats") (not $v.events.nats.existingSecret) (not $v.events.nats.url) -}}
  {{- $errors = append $errors "events.nats.url is required when events.backend=nats (or set events.nats.existingSecret)" -}}
{{- end -}}
{{- if and $v.mcp.anonymous (not (has $v.mcp.anonymous (list "auto" "never"))) -}}
  {{- $errors = append $errors (printf "mcp.anonymous must be auto or never, got %q" (toString $v.mcp.anonymous)) -}}
{{- end -}}
{{- if and $v.server.logFormat (not (has $v.server.logFormat (list "pretty" "json"))) -}}
  {{- $errors = append $errors (printf "server.logFormat must be pretty or json, got %q" (toString $v.server.logFormat)) -}}
{{- end -}}
{{- if $errors -}}
{{- fail (printf "\n\nNotedThat server configuration:\n  - %s\n\nSee https://github.com/NotedThat/NotedThat/blob/main/docs/CONFIGURATION.md" (join "\n  - " $errors)) -}}
{{- end -}}
{{- end -}}
