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

Each image is tagged with the OpenUSD version it was built from (for example `26.08`). The newest OpenUSD release is also tagged `latest`.

```sh
docker pull ghcr.io/blippar-labs/usd-base:latest
docker pull ghcr.io/blippar-labs/usd-base-ar:26.08
```

Use one as a base for your own image:

```dockerfile
FROM ghcr.io/blippar-labs/usd-base:26.08
RUN python3 -c "from pxr import Usd; print(Usd.GetVersion())"
```

## Publishing

Images are built by the [`publish images`](.github/workflows/publish.yml) workflow. It builds `usd-base` for both architectures, publishes the manifest, and then builds `usd-base-ar` on top of that exact manifest in the same run.

Run it from the **Actions** tab with:

| Input | Default | Meaning |
|---|---|---|
| `usd_version` | `latest` | An OpenUSD release such as `26.08`, or `latest` to resolve the newest upstream release. |
| `force_rebuild` | `false` | Rebuild and republish even if the version already exists in the registry. |

Behaviour:

- An explicit `usd_version` always builds and overwrites that tag.
- `latest` resolves the newest upstream release and builds it only if that tag is not yet in the registry. This is also what the weekly schedule (Mondays, 03:00 UTC) runs, so new OpenUSD releases are picked up automatically.
- Whatever the trigger, if the built version equals the newest upstream release, both images are also tagged `latest`.

## Building locally

```sh
scripts/build-local.sh            # latest upstream release
scripts/build-local.sh 26.05      # a specific release
```

This builds `usd-base:<version>` and then `usd-base-ar:<version>` for the host architecture. Expect an hour or more. See the script header for `IMAGE_PREFIX` and `ONLY` options.

`scripts/resolve-version.sh` turns `latest` into a concrete OpenUSD version and validates explicit versions. The workflow uses the same script.

## Repository layout

```
.github/workflows/publish.yml   build + publish workflow
scripts/                        local build and version helpers
usd-base/                       OpenUSD toolchain image
usd-base-ar/                    OpenUSD + Apple AR schemas image
```

Each image lives in its own folder with a `Dockerfile` and a `README.md`. More images may be added over time.

## Acknowledgements

- [Pixar OpenUSD](https://github.com/PixarAnimationStudios/OpenUSD)
- [Apple USDZ Schemas for AR](https://developer.apple.com/documentation/arkit/usdz_schemas_for_ar)
- Originally developed at [Plattar](https://github.com/Plattar) as `python-usd` and `python-usd-ar`.
