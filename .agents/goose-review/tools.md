This repository holds Helm charts, no application code:

- `charts/common`: a library chart (`type: library`) of `common.*` template
  helpers in `templates/_*.tpl`.
- `charts/server`: the NotedThat server chart. It depends on the *released*
  common chart from `oci://ghcr.io/notedthat/charts` (`0.x.x`, locked in
  `Chart.lock`), not on `charts/common` here: a change to `charts/common`
  reaches the server chart only once common is released.
- `ci/common` and `ci/server`: test charts that `.github/workflows/lint.yaml`
  and `test.yaml` render with `helm template`; `ci/common` uses
  `file://../../charts/common`.
- Release-please (`release-please-config.json`,
  `.release-please-manifest.json`) owns each chart's `Chart.yaml` `version`
  and `CHANGELOG.md`; Renovate bumps the server's `appVersion`.

Hints:

- Where a helper is used: `rg -n 'include "common\.names\.fullname"' charts/ ci/`;
  where a value is read: `rg -n '\.Values\.ingress\b' charts/server/templates/`.
- A helper's definition: `rg -n 'define "common\.' charts/common/templates/`.
- Rendering works offline for the common chart only:
  `helm dependency build ci/common && helm template t ci/common`, with
  `--set key=value` to try an input. The server chart needs the OCI registry,
  which the review cannot reach: read its templates instead.
- Do not run `helm dependency update`, `helm pull` or anything else that
  needs the network.
