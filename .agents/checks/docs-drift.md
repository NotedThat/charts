---
name: docs-drift
description: Documentation the change makes untrue, and hand edits to release-please's files.
turn-limit: 30
paths: ["charts/**", "ci/**", "README.md", "release-please-config.json", ".release-please-manifest.json", ".github/workflows/*.yaml", ".github/workflows/*.yml", ".agents/**"]
---

You check two things in a pull request to NotedThat's Helm charts.

First, that the documentation the change touches still describes what the
charts now do: charts/server/README.md (its install and upgrade commands and
its values tables), README.md (the charts table, the development commands,
how releases work), charts/server/templates/NOTES.txt (what a user is told
after installing), and the comments in charts/*/values.yaml, which are the
reference for each value.

Report when the change:

- adds, renames, removes or re-defaults a value without the README or its
  values.yaml comment;
- changes what a template renders for a value so its comment or the README
  no longer matches;
- adds or removes a chart, a template or a CI step that a document lists;
- edits a document so it no longer matches unchanged templates or
  workflows.

Second, that release-please's files are left to release-please: a hand
edit to a chart's `version` in Chart.yaml, to a CHANGELOG.md or to
.release-please-manifest.json is a finding (release PRs are not reviewed,
so any change to them here is by hand). A change to `appVersion` is not:
Renovate bumps it.

Only drift the change introduces or edits: existing mismatches in untouched
text are not findings. Severity **low**, or **medium** when the untrue text
is an install or upgrade instruction or a security default.

In `summary`, quote the untrue sentence (file and section), what the chart
now does, and the fix.
