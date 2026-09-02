# converter-base

3D asset conversion toolchain built on [`usd-base-ar`](../usd-base-ar). It is the baseline image for pipelines that convert glTF/GLB to USDZ and optimise glTF/GLB for the web.

```sh
docker pull ghcr.io/blippar-labs/converter-base:latest
docker pull ghcr.io/blippar-labs/converter-base:1.3.0
```

## What's inside

| Tool | Purpose | Pinned by |
|---|---|---|
| Pixar OpenUSD + Apple AR schemas | USD/USDZ toolchain and Python bindings (from `usd-base-ar`) | `USD_VERSION` |
| [`usd_from_gltf`](https://github.com/Plattar/usd_from_gltf) (Plattar fork) | glTF/GLB to USDZ for AR Quick Look | `UFG_COMMIT` |
| [`gltf-transform`](https://gltf-transform.dev) | glTF optimisation: WebP, KTX2, meshopt, Draco, simplify, resize | `GLTF_TRANSFORM_VERSION` |
| [`ktx`](https://github.com/KhronosGroup/KTX-Software) (KTX-Software) | KTX2 / Basis Universal encoding, called by `gltf-transform etc1s` and `uastc` | `KTX_VERSION` |
| [`gltfpack`](https://github.com/zeux/meshoptimizer) | meshoptimizer's standalone glTF optimiser (native build, mesh-only) | `MESHOPTIMIZER_VERSION` |
| [Node.js](https://nodejs.org) LTS | Runtime for `gltf-transform` and downstream tooling | `NODE_VERSION` |

All versions are `ARG`s at the top of the [`Dockerfile`](Dockerfile). All tools are on `PATH`.

## Usage

```sh
# glTF/GLB -> USDZ
usd_from_gltf model.glb model.usdz

# Optimise a GLB for the web
gltf-transform optimize model.glb model.opt.glb --texture-compress webp
gltf-transform uastc model.glb model.ktx2.glb        # KTX2 (UASTC) textures
gltf-transform etc1s model.glb model.ktx2.glb        # KTX2 (ETC1S) textures
gltfpack -i model.glb -o model.pack.glb -cc          # meshopt compression

# USD from Python
python3 -c "from pxr import Usd; print(Usd.Stage.Open('model.usdz').ExportToString())"
```

Environment variables exported by the image, in addition to those from `usd-base`:

| Variable | Value |
|---|---|
| `CONVERTER_PREFIX` | `/opt/converter` |
| `UFG_PATH`, `UFG_BIN_PATH` | `usd_from_gltf` install prefix and binary directory |
| `UFG_LIB_PATH` | static libraries (`libconvert.a` etc.) for linking against `ufg::ConvertGltfToUsd` |
| `UFG_PLUGIN_PATH` | USD plugin directory containing the UFG glTF file format plugin |
| `PXR_PLUGINPATH_NAME` | set to `UFG_PLUGIN_PATH`, so `Usd.Stage.Open("model.glb")` works from Python |
| `NODE_VERSION`, `KTX_VERSION`, `GLTF_TRANSFORM_VERSION` | the pinned tool versions |

## Notes

**KTX2 and WebP are for GLB output only.** USDZ does not support either format, so convert to USDZ from the PNG/JPEG variant of a model and produce the KTX2/WebP variant separately for web delivery.

**`usd_from_gltf` is the tool to watch.** It is the only converter that reliably produces USDZ files that work for web AR (AR Quick Look); Adobe's USD file format plugins are a maintained alternative but web AR is not a priority for them. Upstream Google development stopped years ago and the Plattar fork carries the OpenUSD compatibility patches. It builds and works against OpenUSD 26.05 today, but expect to revisit it when OpenUSD moves on.

**`usdchecker` reports two issues on UFG output.** The USDZ files it writes omit `metersPerUnit` stage metadata and type the `uvset` `varname` input as `token` rather than `string`. AR Quick Look accepts them, so the smoke test treats `usdchecker` as informational. Both are candidates for a fork patch.

**The UFG USD plugin registers but cannot read yet.** `PXR_PLUGINPATH_NAME` registers UFG's glTF `SdfFileFormat` plugin, but in the current fork commit `Usd.Stage.Open("model.glb")` fails with an assertion in `convert/converter.cc` (`MakeAbsolutePath` receives a full path). Convert with the `usd_from_gltf` CLI instead. Another fork item to revisit.

**gltf-transform does not use gltfpack.** Its `meshopt`, `simplify`, `weld` and `optimize` commands use the meshoptimizer WebAssembly library that installs with the CLI. `gltfpack` is included as a standalone tool. It is built without Basis Universal because KTX2 encoding is handled by `gltf-transform` and `ktx`.

## Versioning and publishing

This image has its own semantic version, independent of OpenUSD. The OpenUSD version it builds on is pinned by the `USD_VERSION` `ARG` in the `Dockerfile` (currently `26.05`) and must already be published as `usd-base-ar:<USD_VERSION>`.

Releases are built by the [`publish converter-base`](../.github/workflows/publish-converter.yml) workflow, triggered by pushing a semantic version tag:

```sh
git tag 1.3.0
git push origin 1.3.0
```

The workflow resolves the exact `usd-base-ar` manifest digest, builds `linux/amd64` and `linux/arm64`, smoke tests each platform image (real glTF to USDZ conversion, KTX2 and WebP encodes, gltfpack), then publishes a multi-arch manifest tagged `1.3.0`, `1.3` and `latest`.

To move to a new OpenUSD release or tool version, bump the relevant `ARG` in the `Dockerfile` and cut a new tag.

## Building locally

```sh
ONLY=converter scripts/build-local.sh 26.05           # FROM usd-base-ar:26.05 (local or IMAGE_PREFIX)
scripts/smoke-test-converter.sh converter-base:dev    # exercise every tool
```

See the header of [`scripts/build-local.sh`](../scripts/build-local.sh) for `IMAGE_PREFIX`, `CONVERTER_VERSION` and `BASE_IMAGE` options.
