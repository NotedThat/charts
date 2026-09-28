# Changelog

## [0.2.0](https://github.com/NotedThat/charts/compare/server-v0.1.2...server-v0.2.0) (2026-09-28)


### ⚠ BREAKING CHANGES

* **server:** metrics.port is removed and metrics are scraped on the new `metrics` port; configuration previously passed through extraEnvVars belongs in the new value blocks; readiness uses /readyz; networkPolicy.allowExternalEgress defaults to true.

### Features

* **server:** support NotedThat 0.12 configuration ([f12217b](https://github.com/NotedThat/charts/commit/f12217b6c16c237a9bcf06008aa8089ef8c3c812))

## [0.1.2](https://github.com/NotedThat/charts/compare/server-v0.1.1...server-v0.1.2) (2026-07-14)


### Bug Fixes

* **server:** update docker tag to 0.1.2 ([01c3179](https://github.com/NotedThat/charts/commit/01c3179c0e119a8faadf531c5d1d2b21425e8a20))
* **server:** update docker tag to 0.1.3 ([5784920](https://github.com/NotedThat/charts/commit/5784920d77f24c3106da974b6e5ecbdc380041c0))

## [0.1.1](https://github.com/NotedThat/charts/compare/server-v0.1.0...server-v0.1.1) (2026-07-08)


### Features

* **server:** enable release automation for the server chart ([#1](https://github.com/NotedThat/charts/issues/1)) ([da2de9e](https://github.com/NotedThat/charts/commit/da2de9edcf97ac803c3a0f1376d291ed68394f21))
