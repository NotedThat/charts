# NotedThat Server Helm Chart

Helm chart for deploying [NotedThat](https://github.com/NotedThat/NotedThat) — a
markdown-first knowledgebase with HTTP API, WebDAV, and remote MCP — on
Kubernetes.

The chart wraps the `ghcr.io/notedthat/server` container image and ships with
sane defaults for a single-replica production install: non-root pod security
context matching the image's baked-in UID (`10001`), `/healthz` liveness and
readiness probes, an optional Ingress, an optional HorizontalPodAutoscaler, a
PodDisruptionBudget, a NetworkPolicy, and optional Prometheus scraping (both
`ServiceMonitor` and pod-annotation modes).

## Install

```bash
helm install my-notedthat oci://ghcr.io/notedthat/charts/server \
  --version 0.1.0 \
  --namespace notedthat \
  --create-namespace
```

## Upgrade

```bash
helm upgrade my-notedthat oci://ghcr.io/notedthat/charts/server \
  --version 0.1.0 \
  --namespace notedthat
```

## Uninstall

```bash
helm uninstall my-notedthat --namespace notedthat
```

## Configuration

See [`values.yaml`](values.yaml) for every knob the chart exposes. The most
commonly overridden values:

| Key | Default | Description |
|-----|---------|-------------|
| `image.tag` | `""` (falls back to `Chart.appVersion`) | Override to pin a specific server release |
| `replicaCount` | `1` | Number of replicas when `autoscaling.enabled=false` |
| `resourcesPreset` | `small` | One of `nano`, `micro`, `small`, `medium`, `large`, `xlarge`, `2xlarge` (from `common` chart) |
| `ingress.enabled` | `false` | Expose the server through an Ingress |
| `ingress.hostname` | `server.notedthat.local` | Ingress host |
| `autoscaling.enabled` | `false` | Enable HPA — requires `resources` (not just `resourcesPreset`) |
| `networkPolicy.enabled` | `true` | Restrict ingress + egress traffic to/from the pod |
| `metrics.enabled` | `false` | Enable Prometheus scrape metadata (does not itself add auth to `/metrics` — restrict via `networkPolicy`) |
| `metrics.serviceMonitor.enabled` | `false` | Create a `monitoring.coreos.com/v1` `ServiceMonitor` (requires the CRD) |

### Supplying NotedThat configuration

The container reads its configuration from environment variables — see the
[application `.env.example`](https://github.com/NotedThat/NotedThat/blob/main/.env.example)
for the full list. Pass them through `extraEnvVars`:

```yaml
extraEnvVars:
  - name: NOTEDTHAT_API_TOKEN
    valueFrom:
      secretKeyRef: { name: notedthat-api, key: token }
  - name: NOTEDTHAT_KBS
    value: notes,scratch
  - name: NOTEDTHAT_S3_REGION
    value: us-east-1
  - name: NOTEDTHAT_S3_ENDPOINT_URL
    value: http://seaweedfs.storage.svc.cluster.local:8333
  - name: NOTEDTHAT_S3_FORCE_PATH_STYLE
    value: "true"
  - name: NOTEDTHAT_S3_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef: { name: notedthat-s3, key: access-key-id }
  - name: NOTEDTHAT_S3_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef: { name: notedthat-s3, key: secret-access-key }
  - name: NOTEDTHAT_QDRANT_URL
    value: http://qdrant.storage.svc.cluster.local:6334
```

## Source

- Chart: <https://github.com/NotedThat/charts>
- Server: <https://github.com/NotedThat/NotedThat>

## License

The chart itself is [MIT](../../LICENSE)-licensed. The NotedThat server it
deploys is MPL-2.0-licensed.
