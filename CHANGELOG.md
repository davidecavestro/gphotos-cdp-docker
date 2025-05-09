# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2025-04-26
### :bug: Bug Fixes
- [`5de340a`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/5de340a024248e9273e3e94d57d13ea1e692827f) - quote filenames as they can contain spaces ( see [#2](https://github.com/davidecavestro/gphotos-cdp-docker/pull/2) ) *(commit by [@davidecavestro](https://github.com/davidecavestro))*
- [`b898b8d`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/b898b8dc271c94b4aee62097cf7e41184ca680cb) - avoid using awk to support filenames with spaces ( see [#2](https://github.com/davidecavestro/gphotos-cdp-docker/pull/2) ) *(commit by [@davidecavestro](https://github.com/davidecavestro))*


## [1.3.0] - 2024-12-01
### :bug: Bug Fixes
- [`a055649`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/a055649be5b052c46599a93d1aafb36fdecb684c) - try to use a supported version of headless shell and cdproto *(commit by [@davidecavestro](https://github.com/davidecavestro))*
- [`6560ec2`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/6560ec219969707a571ed3d1351cbff0eb6bb45f) - no way to resolve names from CLI *(commit by [@davidecavestro](https://github.com/davidecavestro))*

### :wrench: Chores
- [`36d1240`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/36d124086fafd63f94035c606b462da8ee5207f9) - fix dockerhub readme path *(commit by [@davidecavestro](https://github.com/davidecavestro))*
- [`f8e5c37`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/f8e5c37a96f14f5c4f3c0d324bce28815ff7829b) - bump up deps *(commit by [@davidecavestro](https://github.com/davidecavestro))*


## [1.2.0] - 2024-07-25
### :sparkles: New Features
- [`96e0f44`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/96e0f4450ca826cf23160994a52007ede47d254d) - use fork with support for timeout control *(commit by [@davidecavestro](https://github.com/davidecavestro))*

### :bug: Bug Fixes
- [`f8302ec`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/f8302ecc92aa732f73728a0cf3c30b634078acf8) - clone repo from GH action to avoid unwanted caching *(commit by [@davidecavestro](https://github.com/davidecavestro))*

### :wrench: Chores
- [`dbed8a1`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/dbed8a12e93f31cec7e46bcc8fb0308f18b53864) - code cleanup *(commit by [@davidecavestro](https://github.com/davidecavestro))*
- [`86227a2`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/86227a2428e4022e62274b9d55d7347ee47f03bb) - latest just from tags *(commit by [@davidecavestro](https://github.com/davidecavestro))*
- [`70cb4df`](https://github.com/davidecavestro/gphotos-cdp-docker/commit/70cb4dfcdd40940863303bdaadbf59f5db979536) - pin version *(commit by [@davidecavestro](https://github.com/davidecavestro))*


## [1.1.1] - 2024-06-13
### :wrench: Chores
- [`7609d4f`](https://github.com/davidecavestro/docker-gphotos-cdp/commit/7609d4f5f0ae99ea72d4d15e6ca2b8dbbbf0c27a) - code cleanup *(commit by [@davidecavestro](https://github.com/davidecavestro))*
- [`3eed95a`](https://github.com/davidecavestro/docker-gphotos-cdp/commit/3eed95acfc0b4b09d47918b0fc12cdc8a5b37a88) - update changelog on release *(commit by [@davidecavestro](https://github.com/davidecavestro))*

[1.1.1]: https://github.com/davidecavestro/docker-gphotos-cdp/compare/1.1.0...1.1.1
[1.2.0]: https://github.com/davidecavestro/gphotos-cdp-docker/compare/1.1.2...1.2.0
[1.3.0]: https://github.com/davidecavestro/gphotos-cdp-docker/compare/1.2.0...1.3.0
[1.3.1]: https://github.com/davidecavestro/gphotos-cdp-docker/compare/1.3.0...1.3.1
