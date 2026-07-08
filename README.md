# NotedThat Helm Charts

Helm charts for deploying [NotedThat](https://github.com/NotedThat) on Kubernetes.

Charts are published as OCI artifacts to `ghcr.io/notedthat/charts`.

## Charts

| Chart | Description | Status |
|-------|-------------|--------|
| [common](charts/common) | Library chart with shared template helpers | Released as `oci://ghcr.io/notedthat/charts/common` |
| [server](charts/server) | NotedThat application server | Held back until `common` is published on OCI — release automation and CI validation for `server` are paused (see [release-please-config.json](release-please-config.json), [.github/workflows/lint.yaml](.github/workflows/lint.yaml)). |

## Installation

```bash
# Install the server chart (available after server is re-enabled)
helm install my-notedthat oci://ghcr.io/notedthat/charts/server --version 0.1.0
```

## Development

```bash
# Lint the common library chart
helm lint charts/common

# Render common templates with defaults
helm dependency update ci/common
helm template test ci/common
```

### Bringing the server chart back online

Once `common` is published to `oci://ghcr.io/notedthat/charts/common`:

1. Restore `charts/server` in [release-please-config.json](release-please-config.json) and [.release-please-manifest.json](.release-please-manifest.json).
2. Restore the `server` lint + template steps in [.github/workflows/lint.yaml](.github/workflows/lint.yaml) and [.github/workflows/test.yaml](.github/workflows/test.yaml).
3. Land a conventional commit touching `charts/server/` — release-please opens a release PR; merging it publishes `server` to `oci://ghcr.io/notedthat/charts/server`.

## Releases

Releases are automated via [release-please](https://github.com/googleapis/release-please).
Merging a conventional commit to `main` opens a release PR; merging that PR
publishes the chart to `oci://ghcr.io/notedthat/charts`.

Kubernetes version support: `>=1.28.0`.

## License

[MIT](LICENSE)
