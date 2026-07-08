{{/*
Resolve the ServiceAccount name to use.
Usage:
{{ include "common.rbac.serviceAccountName" (dict "serviceAccount" .Values.serviceAccount "context" $) }}
*/}}
{{- define "common.rbac.serviceAccountName" -}}
{{- if .serviceAccount.create -}}
  {{- default (include "common.names.fullname" .context) .serviceAccount.name -}}
{{- else -}}
  {{- default "default" .serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Render a ServiceAccount resource.
Usage:
{{ include "common.rbac.serviceAccount" (dict "serviceAccount" .Values.serviceAccount "labels" (include "common.labels.standard" .) "annotations" .Values.serviceAccount.annotations "context" $) }}
*/}}
{{- define "common.rbac.serviceAccount" -}}
{{- if .serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.rbac.serviceAccountName" (dict "serviceAccount" .serviceAccount "context" .context) }}
  namespace: {{ include "common.names.namespace" .context }}
  labels: {{- include "common.labels.standard" .context | nindent 4 }}
  {{- if or .serviceAccount.annotations .annotations }}
  annotations:
    {{- if .serviceAccount.annotations }}
    {{- include "common.tplvalues.render" (dict "value" .serviceAccount.annotations "context" .context) | nindent 4 }}
    {{- end }}
    {{- if .annotations }}
    {{- include "common.tplvalues.render" (dict "value" .annotations "context" .context) | nindent 4 }}
    {{- end }}
  {{- end }}
automountServiceAccountToken: {{ default false .serviceAccount.automountServiceAccountToken }}
{{- end -}}
{{- end -}}

{{/*
Render a Role resource.
Usage:
{{ include "common.rbac.role" (dict "name" "my-role" "rules" .Values.rbac.rules "labels" (include "common.labels.standard" .) "context" $) }}
*/}}
{{- define "common.rbac.role" -}}
apiVersion: {{ include "common.capabilities.rbac.apiVersion" .context }}
kind: Role
metadata:
  name: {{ .name }}
  namespace: {{ include "common.names.namespace" .context }}
  labels: {{- include "common.labels.standard" .context | nindent 4 }}
  {{- if .labels }}
  {{- include "common.tplvalues.render" (dict "value" .labels "context" .context) | nindent 4 }}
  {{- end }}
rules: {{- toYaml .rules | nindent 2 }}
{{- end -}}

{{/*
Render a ClusterRole resource.
Usage:
{{ include "common.rbac.clusterRole" (dict "name" "my-cluster-role" "rules" .Values.rbac.rules "labels" (include "common.labels.standard" .) "context" $) }}
*/}}
{{- define "common.rbac.clusterRole" -}}
apiVersion: {{ include "common.capabilities.rbac.apiVersion" .context }}
kind: ClusterRole
metadata:
  name: {{ .name }}
  labels: {{- include "common.labels.standard" .context | nindent 4 }}
  {{- if .labels }}
  {{- include "common.tplvalues.render" (dict "value" .labels "context" .context) | nindent 4 }}
  {{- end }}
rules: {{- toYaml .rules | nindent 2 }}
{{- end -}}

{{/*
Render a RoleBinding resource.
Usage:
{{ include "common.rbac.roleBinding" (dict "name" "my-binding" "roleName" "my-role" "serviceAccountName" "my-sa" "labels" (include "common.labels.standard" .) "context" $) }}
*/}}
{{- define "common.rbac.roleBinding" -}}
apiVersion: {{ include "common.capabilities.rbac.apiVersion" .context }}
kind: RoleBinding
metadata:
  name: {{ .name }}
  namespace: {{ include "common.names.namespace" .context }}
  labels: {{- include "common.labels.standard" .context | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ .roleName }}
subjects:
  - kind: ServiceAccount
    name: {{ .serviceAccountName }}
    namespace: {{ include "common.names.namespace" .context }}
{{- end -}}

{{/*
Render a ClusterRoleBinding resource.
Usage:
{{ include "common.rbac.clusterRoleBinding" (dict "name" "my-binding" "clusterRoleName" "my-cluster-role" "serviceAccountName" "my-sa" "labels" (include "common.labels.standard" .) "context" $) }}
*/}}
{{- define "common.rbac.clusterRoleBinding" -}}
apiVersion: {{ include "common.capabilities.rbac.apiVersion" .context }}
kind: ClusterRoleBinding
metadata:
  name: {{ .name }}
  labels: {{- include "common.labels.standard" .context | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ .clusterRoleName }}
subjects:
  - kind: ServiceAccount
    name: {{ .serviceAccountName }}
    namespace: {{ include "common.names.namespace" .context }}
{{- end -}}
