This repository holds Helm charts, no application code:

- `charts/common`: a library chart (`type: library`) of `common.*` template
  helpers in `templates/_*.tpl`.
- `charts/server`: the NotedThat server chart. It depends on the *released*
  common chart from `oci://ghcr.io/notedthat/charts` (`0.x.x`, locked in
  `Chart.lock`), not on `charts/common` here: a change to `charts/common`
  reaches the server chart only once common is released.
- `ci/common` and `ci/server`: test charts that `.github/workflows/lint.yaml`
  and `test.yaml` render with `helm template`; `ci/common` uses
  `file://../../charts/common`, `ci/server` `file://../../charts/server`.
- Release-please (`release-please-config.json`,
  `.release-please-manifest.json`) owns each chart's `Chart.yaml` `version`
  and `CHANGELOG.md`; Renovate bumps the server's `appVersion`.

Every chart's dependencies are built, so these run offline:

- Render: `helm template t ci/server`, `helm template t ci/common`, or the
  chart itself with the values that matter:
  `helm template t charts/server --set ingress.enabled=true`.
- Lint: `helm lint charts/server`, `helm lint charts/common`.
- Validate: `helm template t ci/server | kubeconform -strict -summary
  -kubernetes-version 1.28.0 -schema-location "$KUBE_SCHEMAS"
  -ignore-missing-schemas` (ServiceMonitor has no schema, so it is
  skipped). The ci/common test ConfigMap holds booleans and numbers on
  purpose: it fails validation, and that is not a finding.
- Lint for security and reliability: `helm template t ci/server |
  kube-linter lint -`. It reports what is already there too (the default
  PodDisruptionBudget, for one).
- Workflows: `actionlint .github/workflows/<file>`.

A lint or validation error is a finding only if the change introduced it.
To see the base, render it outside the checkout:
`mkdir -p "$RUNNER_TEMP/base" && git archive <base> | tar -x -C "$RUNNER_TEMP/base"`,
then `cp -r charts/server/charts "$RUNNER_TEMP/base/charts/server/"` and
run the same command there (for ci/common or ci/server, `helm dependency
build` it there first; its file:// dependency needs no network). Quote the
error from the head that the base does not have.

Searching:

- Where a helper is used: `rg -n 'include "common\.names\.fullname"' charts/ ci/`;
  where a value is read: `rg -n '\.Values\.ingress\b' charts/server/templates/`.
- A helper's definition: `rg -n 'define "common\.' charts/common/templates/`.

Do not run `helm dependency update`, `helm pull` or anything else that
needs the network.
