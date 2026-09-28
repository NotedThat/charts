# NotedThat Server Helm Chart

Helm chart for deploying [NotedThat](https://github.com/NotedThat/NotedThat) — a
markdown-first knowledgebase with HTTP API, WebDAV, and remote MCP — on
Kubernetes.

The chart wraps the `ghcr.io/notedthat/server` image and deploys it against an
S3-compatible object store, [Qdrant](https://qdrant.tech/) and an
OpenAI-compatible embedding endpoint, none of which it installs. It ships with:

- a non-root, read-only-root-filesystem pod (UID `10001`) with a disk-backed
  staging volume for uploads
- `/healthz` startup and liveness probes, and a `/readyz` readiness probe
- a shutdown grace period sized for the server's request timeouts and indexer
  drain
- an optional Ingress, HorizontalPodAutoscaler, PodDisruptionBudget and
  NetworkPolicy
- optional Prometheus scraping of the separate metrics listener, through a
  `ServiceMonitor` or pod annotations

## Install

Create the secrets (or pass the values inline; the chart then stores them in a
Secret of its own):

```bash
kubectl create namespace notedthat
kubectl -n notedthat create secret generic notedthat-auth \
  --from-literal=api-token="$(openssl rand -hex 32)" \
  --from-literal=webdav-username=webdav \
  --from-literal=webdav-password="$(openssl rand -hex 32)"
kubectl -n notedthat create secret generic notedthat-s3 \
  --from-literal=access-key-id=... --from-literal=secret-access-key=...
kubectl -n notedthat create secret generic notedthat-embedding \
  --from-literal=api-key=sk-...
```

A minimal `values.yaml`:

```yaml
auth:
  existingSecret: notedthat-auth
knowledgebases: [notes, scratch]
s3:
  region: us-east-1
  endpointUrl: http://seaweedfs.storage.svc.cluster.local:8333
  forcePathStyle: true
  existingSecret: notedthat-s3
qdrant:
  url: http://qdrant.storage.svc.cluster.local:6334
embedding:
  endpointUrl: https://api.openai.com
  model: text-embedding-3-small
  dimensions: 1536
  existingSecret: notedthat-embedding
```

```bash
helm install notedthat oci://ghcr.io/notedthat/charts/server \
  --namespace notedthat -f values.yaml
```

A missing required value fails at render time and lists every problem, instead
of producing a pod that crash-loops on the server's own startup validation.

## Configuration

Every value maps onto a server setting documented in
[`docs/CONFIGURATION.md`](https://github.com/NotedThat/NotedThat/blob/main/docs/CONFIGURATION.md);
[`values.yaml`](values.yaml) names the variable next to each key. Optional
settings left empty are not rendered at all, so the server's own defaults
apply.

| Block | Required | Settings |
|-------|----------|----------|
| `auth` | yes | Service token and WebDAV Basic credentials (`NOTEDTHAT_API_TOKEN`, `NOTEDTHAT_WEBDAV_*`) |
| `knowledgebases` | yes | `NOTEDTHAT_KBS` |
| `s3` | yes | Object store (`NOTEDTHAT_S3_*`). Only the `s3` storage backend is supported by the chart |
| `qdrant` | yes | `NOTEDTHAT_QDRANT_*` |
| `embedding` | yes | `EMBEDDING_*` |
| `oidc` | no | Identity-provider JWTs (`NOTEDTHAT_OIDC_*`), including a CA bundle from a ConfigMap or Secret |
| `events` | no | `none` (default), `memory` or `nats` (`NOTEDTHAT_EVENTS_*`, `NOTEDTHAT_NATS_*`) |
| `mcp` | no | `/mcp` Host/Origin allow-lists, anonymous access and limits (`NOTEDTHAT_MCP_*`) |
| `server` | no | Log format, `RUST_LOG`, request bounds and timeouts |
| `staging` | no | Mount path and `sizeLimit` of the upload staging volume (`NOTEDTHAT_UPLOAD_TMP_DIR`) |

### Secrets

Each block with credentials (`auth`, `s3`, `qdrant`, `embedding`,
`events.nats`) takes either inline values or an `existingSecret`. The keys
looked up in an existing Secret are set under that block's `secretKeys` and
default to:

| Block | Keys |
|-------|------|
| `auth` | `api-token`, `webdav-username`, `webdav-password` |
| `s3` | `access-key-id`, `secret-access-key` |
| `qdrant` | `api-key` |
| `embedding` | `api-key` |
| `events.nats` | `nats-url` (the URL can carry credentials) |

Access rules and settings are a startup snapshot. The pod carries a checksum of
the chart-managed Secret, so changing an inline value rolls it. A change to an
existing Secret needs a `kubectl rollout restart`.

### Ingress and MCP

When `ingress.enabled` is set and `mcp.allowedHosts` / `mcp.allowedOrigins`
are empty, the chart sets them to the ingress hostname and URL. MCP rejects
any `Host` outside that list. With `oidc.issuer` set, `oidc.resource` defaults
to the ingress URL.

The proxy in front of the server has to leave responses unbuffered (`GET /mcp`
and the events stream are long-lived) and keep a read timeout well above 15 s.
It must not cap request bodies (WebDAV) and must preserve `Host`. For
ingress-nginx:

```yaml
ingress:
  enabled: true
  className: nginx
  hostname: notes.example.com
  tls: true
  annotations:
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
```

See [`docs/OPERATIONS.md`](https://github.com/NotedThat/NotedThat/blob/main/docs/OPERATIONS.md#the-reverse-proxy)
for the full list.

### OIDC

```yaml
oidc:
  issuer: https://auth.example.com/application/o/notedthat/   # exactly as `iss`, trailing slash included
  audience: [notedthat-client-id]
  caCert:
    existingConfigMap: internal-ca   # optional; key `ca.crt`
```

### Metrics

`metrics.enabled` opens the server's separate metrics listener on
`containerPorts.metrics` (9090) and adds a `metrics` port to the Service. The
exposition is unauthenticated. It is never routed by the Ingress, and the
NetworkPolicy admits only `networkPolicy.metricsFrom` to it (any in-cluster pod
when empty). Pick one discovery mode: `metrics.serviceMonitor.enabled` (needs
the Prometheus Operator CRDs) or `metrics.podAnnotations.enabled`.

### Upload staging and ephemeral storage

WebDAV uploads and index snapshots are staged on a disk-backed `emptyDir` at
`/var/lib/notedthat-staging`. Budget about 5 GiB per concurrent maximum-size
upload. The volume counts against the container's `ephemeral-storage` limit,
which is 2 GiB with the default `resourcesPreset: small`, so set `resources`
explicitly (and `staging.sizeLimit`) when large uploads are expected.

### Replicas

The chart defaults to one replica. MCP sessions live in a single process, so
more replicas need sticky routing for `/mcp`, and `events.backend: memory`
keeps one event log per replica, so use `nats` instead.

### NetworkPolicy egress

The server has to reach the object store, Qdrant, the embedding endpoint, and
NATS and the OIDC issuer when they are configured, and every one of them is
contacted before the listener binds. `networkPolicy.allowExternalEgress`
therefore defaults to `true`. To tighten it, set it to `false` and list those
destinations in `networkPolicy.extraEgress`.

## Upgrading from 0.1.x

Chart 0.1.x targeted server 0.1.3. Server 0.12.0 changes enough that values
need attention:

- **Configuration moved out of `extraEnvVars`** into the blocks above. Remove
  `NOTEDTHAT_*` / `EMBEDDING_*` entries from `extraEnvVars`: a duplicate
  variable in the pod spec is ambiguous.
- **`PORT` is gone.** The server reads `NOTEDTHAT_LISTEN_ADDR`, which the chart
  sets from `containerPorts.http`.
- **Metrics moved to their own port.** `metrics.port` is removed, the
  ServiceMonitor scrapes the `metrics` port (9090), and `/metrics` on the http
  port now answers 404.
- **Readiness uses `/readyz`**, and a startup probe covers backend
  provisioning.
- **`networkPolicy.allowExternalEgress` defaults to `true`.**
- **`terminationGracePeriodSeconds` is 165** (WebDAV request timeout plus the
  indexer drain).

Read the server's
[`CHANGELOG.md`](https://github.com/NotedThat/NotedThat/blob/main/CHANGELOG.md)
for the versions you cross as well. In particular, manifests using the removed
`public_read` field come up private.

## Uninstall

```bash
helm uninstall notedthat --namespace notedthat
```

Objects live in the object store and are not touched. The search index in
Qdrant can be rebuilt from them.

## Source

- Chart: <https://github.com/NotedThat/charts>
- Server: <https://github.com/NotedThat/NotedThat>

## License

The chart itself is [MIT](../../LICENSE)-licensed. The NotedThat server it
deploys is MPL-2.0-licensed.
