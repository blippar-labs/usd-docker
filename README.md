# usd-docker

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat)](LICENSE)
[![publish images](https://github.com/blippar-labs/usd-docker/actions/workflows/publish.yml/badge.svg)](https://github.com/blippar-labs/usd-docker/actions/workflows/publish.yml)

Docker images for converting and processing USD/USDZ 3D files, built for use as a base or CI component in other projects.

Building [Pixar OpenUSD](https://github.com/PixarAnimationStudios/OpenUSD) from source takes a long time, so these images compile it once per release and publish multi-arch manifests (`linux/amd64` and `linux/arm64`) to the GitHub Container Registry.

## Images

| Image | Description | Folder |
|---|---|---|
| [`ghcr.io/blippar-labs/usd-base`](https://github.com/blippar-labs/usd-docker/pkgs/container/usd-base) | Pre-built OpenUSD toolchain with Python bindings. | [`usd-base/`](usd-base) |
| [`ghcr.io/blippar-labs/usd-base-ar`](https://github.com/blippar-labs/usd-docker/pkgs/container/usd-base-ar) | `usd-base` plus Apple's `Preliminary_*` USDZ AR schemas compiled in. | [`usd-base-ar/`](usd-base-ar) |
| [`ghcr.io/blippar-labs/converter-base`](https://github.com/blippar-labs/usd-docker/pkgs/container/converter-base) | `usd-base-ar` plus `usd_from_gltf`, `gltf-transform`, KTX-Software, `gltfpack` and Node.js. glTF to USDZ conversion and GLB optimisation (WebP, KTX2, meshopt). | [`converter-base/`](converter-base) |

`usd-base` and `usd-base-ar` are tagged with the OpenUSD version they were built from (for example `26.08`). The newest OpenUSD release is also tagged `latest`. `converter-base` has its own semantic version (for example `1.3.0`) and pins the OpenUSD version it builds on in its Dockerfile.

```sh
docker pull ghcr.io/blippar-labs/usd-base:latest
docker pull ghcr.io/blippar-labs/usd-base-ar:26.08
docker pull ghcr.io/blippar-labs/converter-base:1.3.0
```

Use one as a base for your own image:

```dockerfile
FROM ghcr.io/blippar-labs/usd-base:26.08
RUN python3 -c "from pxr import Usd; print(Usd.GetVersion())"
```

## Publishing

### OpenUSD images

`usd-base` and `usd-base-ar` are built by the [`publish images`](.github/workflows/publish.yml) workflow. It builds `usd-base` for both architectures, publishes the manifest, and then builds `usd-base-ar` on top of that exact manifest in the same run.

Run it from the **Actions** tab with:

| Input | Default | Meaning |
|---|---|---|
| `usd_version` | `latest` | An OpenUSD release such as `26.08`, or `latest` to resolve the newest upstream release. |
| `force_rebuild` | `false` | Rebuild and republish even if the version already exists in the registry. |

Behaviour:

- An explicit `usd_version` always builds and overwrites that tag.
- `latest` resolves the newest upstream release and builds it only if that tag is not yet in the registry. This is also what the weekly schedule (Mondays, 03:00 UTC) runs, so new OpenUSD releases are picked up automatically.
- Whatever the trigger, if the built version equals the newest upstream release, both images are also tagged `latest`.

### converter-base

`converter-base` is built by the [`publish converter-base`](.github/workflows/publish-converter.yml) workflow, triggered by pushing a semantic version tag:

```sh
git tag 1.3.0
git push origin 1.3.0
```

It reads the pinned `USD_VERSION` from [`converter-base/Dockerfile`](converter-base/Dockerfile), resolves that `usd-base-ar` manifest digest (the OpenUSD images must already be published), builds both architectures, smoke tests them, and publishes `1.3.0`, `1.3` and `latest`. See the [converter-base README](converter-base/README.md) for the tool list and how to bump versions.

## Building locally

```sh
scripts/build-local.sh                        # latest upstream release, all three images
scripts/build-local.sh 26.05                  # a specific release
ONLY=converter scripts/build-local.sh 26.05   # converter-base only, FROM usd-base-ar:26.05
scripts/smoke-test-converter.sh converter-base:dev
```

This builds `usd-base:<version>`, `usd-base-ar:<version>` and `converter-base:dev` for the host architecture. Expect an hour or more for the OpenUSD images; `converter-base` alone takes a few minutes. See the script header for `IMAGE_PREFIX`, `ONLY`, `CONVERTER_VERSION` and `BASE_IMAGE` options.

`scripts/resolve-version.sh` turns `latest` into a concrete OpenUSD version and validates explicit versions. The workflow uses the same script.

## Repository layout

```
.github/workflows/publish.yml            OpenUSD images build + publish workflow
.github/workflows/publish-converter.yml  converter-base build + publish workflow (tag driven)
scripts/                                 local build, smoke test and version helpers
usd-base/                                OpenUSD toolchain image
usd-base-ar/                             OpenUSD + Apple AR schemas image
converter-base/                          glTF -> USDZ conversion and GLB optimisation image
```

Each image lives in its own folder with a `Dockerfile` and a `README.md`. More images may be added over time.

## Acknowledgements

- [Pixar OpenUSD](https://github.com/PixarAnimationStudios/OpenUSD)
- [Apple USDZ Schemas for AR](https://developer.apple.com/documentation/arkit/usdz_schemas_for_ar)
- [Plattar/usd_from_gltf](https://github.com/Plattar/usd_from_gltf) (fork of Google's [usd_from_gltf](https://github.com/google/usd_from_gltf))
- [glTF Transform](https://gltf-transform.dev), [KTX-Software](https://github.com/KhronosGroup/KTX-Software), [meshoptimizer](https://github.com/zeux/meshoptimizer)
- Originally developed at [Plattar](https://github.com/Plattar) as `python-usd`, `python-usd-ar` and `python-xrutils`.
