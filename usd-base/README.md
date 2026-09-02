# usd-base

Pre-built [Pixar OpenUSD](https://github.com/PixarAnimationStudios/OpenUSD) toolchain with Python bindings, on top of `python:3.12-slim`.

```sh
docker pull ghcr.io/blippar-labs/usd-base:latest
docker pull ghcr.io/blippar-labs/usd-base:26.08
```

## What is included

- OpenUSD core libraries, Python bindings and command-line tools (`usdcat`, `usdzip`, `usdchecker`, `usdGenSchema`, ...).
- Built with `--no-imaging --no-usdview --no-draco --no-materialx --no-examples --no-tutorials`.
- `pxrConfig.cmake` and the `cmake/` package configuration are kept so derived images can compile USD plugins against this install.
- Build-only OS packages (compilers, git, cmake) are removed after the build. Derived images reinstall what they need.

## Environment

| Variable | Value |
|---|---|
| `USD_VERSION` | OpenUSD version the image was built from |
| `USD_BUILD_PATH` | `/usr/src/app/xrutils/usd` |
| `USD_BIN_PATH` | `${USD_BUILD_PATH}/bin`, appended to `PATH` |
| `USD_LIB_PATH` | `${USD_BUILD_PATH}/lib`, also set as `LD_LIBRARY_PATH` |
| `USD_PLUGIN_PATH` | `${USD_BUILD_PATH}/plugin/usd` |
| `PYTHONPATH` | `${USD_LIB_PATH}/python` |

## Build arguments

| Argument | Default | Meaning |
|---|---|---|
| `USD_VERSION` | `26.08` | OpenUSD release tag without the leading `v`. |
| `PYTHON_BASE` | `python:3.12-slim-trixie` | Parent image. |

```sh
docker build --build-arg USD_VERSION=26.08 -t usd-base:26.08 .
```

See the [repository README](../README.md) for the publishing workflow.
