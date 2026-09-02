# usd-base-ar

[`usd-base`](../usd-base) plus Apple's [USDZ Schemas for AR](https://developer.apple.com/documentation/arkit/usdz_schemas_for_ar): `Preliminary_AnchoringAPI`, `Preliminary_Behavior`, `Preliminary_Trigger`, `Preliminary_Action`, `Preliminary_ReferenceImage` and `Preliminary_Text`.

These schemas are not part of upstream OpenUSD. At build time they are code-generated with `usdGenSchema` and compiled into the USD install as the `usdInteractive` library, available in Python as `pxr.UsdInteractive`.

```sh
docker pull ghcr.io/blippar-labs/usd-base-ar:latest
docker pull ghcr.io/blippar-labs/usd-base-ar:26.08
```

## How it builds

1. Start from a `usd-base` image (`BASE_IMAGE`).
2. Clone the matching OpenUSD source, using the `USD_VERSION` exported by the base image.
3. Copy `usd_schemas/usdInteractive/` into `pxr/usd/` and run `usdGenSchema`.
4. Re-run `build_usd.py` into the existing install prefix. Third-party dependencies are already present and are skipped, so only USD itself is recompiled.

Because the version comes from the base image, the schemas always match the OpenUSD build they are compiled into.

## Build arguments

| Argument | Default | Meaning |
|---|---|---|
| `BASE_IMAGE` | `ghcr.io/blippar-labs/usd-base:latest` | The `usd-base` image to build on. The publish workflow pins this to the exact manifest digest built in the same run. |

```sh
docker build --build-arg BASE_IMAGE=usd-base:26.08 -t usd-base-ar:26.08 .
```

## Schema sources

`usd_schemas/` contains Apple's schema definition package, redistributed under its MIT licence (see `usd_schemas/LICENSE/LICENSE.txt`).

See the [repository README](../README.md) for the publishing workflow.
