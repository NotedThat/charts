# NotedThat Helm Charts

Helm charts for deploying [NotedThat](https://github.com/NotedThat) on Kubernetes.

Charts are published as OCI artifacts to `ghcr.io/notedthat/charts`.

## Charts

| Chart | Description | Version |
|-------|-------------|---------|
| [server](charts/server) | NotedThat application server | see [Chart.yaml](charts/server/Chart.yaml) |
| [common](charts/common) | Library chart with shared template helpers | see [Chart.yaml](charts/common/Chart.yaml) |

## Installation

```bash
# Install the server chart
helm install my-notedthat oci://ghcr.io/notedthat/charts/server --version 0.1.0
```

## Development

```bash
# Lint the common library chart
helm lint charts/common

# Lint the server application chart (fetches common from OCI as a dep)
helm dependency update charts/server
helm lint charts/server

# Render templates with defaults
helm dependency update ci/server
helm template test ci/server
```

## Releases

Releases are automated via [release-please](https://github.com/googleapis/release-please).
Merging a conventional commit to `main` opens a release PR; merging that PR
publishes the chart to `oci://ghcr.io/notedthat/charts`.

Kubernetes version support: `>=1.28.0`.

## License

[MIT](LICENSE)
