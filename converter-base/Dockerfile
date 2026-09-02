# syntax=docker/dockerfile:1.7

# converter-base: 3D asset conversion toolchain on top of usd-base-ar
#
# A baseline image for pipelines that convert glTF/GLB to USDZ and optimise
# glTF/GLB for the web. It adds the following to usd-base-ar:
#
#   * usd_from_gltf  - Plattar fork of Google's UFG. glTF/GLB -> USDZ.
#                      https://github.com/Plattar/usd_from_gltf
#   * gltf-transform - glTF optimisation CLI (Node.js). Handles WebP, KTX2
#                      (via the `ktx` tool below), meshopt, Draco, simplify...
#                      https://gltf-transform.dev
#   * ktx            - KTX-Software CLI used by gltf-transform for KTX2/Basis
#                      Universal (ETC1S / UASTC) texture encoding.
#                      https://github.com/KhronosGroup/KTX-Software
#   * gltfpack       - meshoptimizer's standalone glTF optimiser (native build).
#                      https://github.com/zeux/meshoptimizer
#   * Node.js LTS    - runtime for gltf-transform and downstream tooling.
#
# usd_from_gltf is the only tool that reliably produces USDZ files that work
# for web AR (AR Quick Look). It builds and works today, but upstream Google
# development stopped years ago and the Plattar fork carries the OpenUSD
# compatibility patches, so expect to revisit it when OpenUSD moves on.
#
# KTX2 and WebP textures are for optimised GLB output only. USDZ does not
# support them, so feed usd_from_gltf the PNG/JPEG variant of a model.
#
# Versioning: this image has its own semantic version (the git tag, e.g. 1.3.0),
# independent of OpenUSD. The OpenUSD version is pinned below via USD_VERSION.

# ---------------------------------------------------------------------------
# Pinned versions. Bump these and cut a new git tag to release.
# ---------------------------------------------------------------------------

# OpenUSD version, i.e. which usd-base-ar tag to build on.
ARG USD_VERSION=26.05
# The publish workflow overrides this with the exact usd-base-ar manifest digest.
ARG BASE_IMAGE=ghcr.io/blippar-labs/usd-base-ar:${USD_VERSION}

# ===========================================================================
# Stage 1: compile native tools against the OpenUSD install in the base image.
# ===========================================================================
FROM ${BASE_IMAGE} AS builder

# Plattar/usd_from_gltf commit (master, tested against OpenUSD 26.05).
ARG UFG_COMMIT=3bad954b944fc097200ea4171fe76f9ded82ca9a
# Draco is a build dependency of UFG (KHR_draco_mesh_compression decoding).
ARG DRACO_VERSION=1.5.7
# stb_image.h is a single header; pinned to a commit for reproducibility.
ARG STB_COMMIT=2c980bb59875b0d32144a71867fbdebb2f77cd20
# meshoptimizer release providing gltfpack.
ARG MESHOPTIMIZER_VERSION=1.2

ENV CONVERTER_PREFIX=/opt/converter

WORKDIR /usr/src/build

RUN set -eux; \
	test -n "${USD_BUILD_PATH}"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		git \
		ca-certificates \
		curl \
		build-essential \
		cmake \
		pkg-config \
		# UFG external deps (see the dependency table in the UFG README).
		libpng-dev \
		libturbojpeg0-dev \
		libgif-dev \
		zlib1g-dev \
		libtclap-dev \
		nlohmann-json3-dev; \
	rm -rf /var/lib/apt/lists/*; \
	mkdir -p "${CONVERTER_PREFIX}/bin"; \
	\
	# --- stb_image.h ---------------------------------------------------------
	mkdir -p /usr/local/include/stb; \
	curl -fsSL \
		"https://raw.githubusercontent.com/nothings/stb/${STB_COMMIT}/stb_image.h" \
		-o /usr/local/include/stb/stb_image.h; \
	\
	# --- Draco (static, PIC) -------------------------------------------------
	# libdraco.a is linked into the ufg_plugin shared library, so it must be
	# position independent (AArch64 PG_HI21 relocations otherwise fail).
	git clone --branch "${DRACO_VERSION}" --depth 1 https://github.com/google/draco draco; \
	cmake -S draco -B draco/build \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DDRACO_TRANSCODER_SUPPORTED=OFF; \
	cmake --build draco/build -j"$(nproc)"; \
	cmake --install draco/build; \
	rm -rf draco; \
	\
	# --- usd_from_gltf (Plattar fork) ----------------------------------------
	git init ufg; \
	git -C ufg remote add origin https://github.com/Plattar/usd_from_gltf; \
	git -C ufg fetch --depth 1 origin "${UFG_COMMIT}"; \
	git -C ufg checkout FETCH_HEAD; \
	cmake -S ufg -B ufg/build \
		-DCMAKE_BUILD_TYPE=Release \
		-DUSD_DIR="${USD_BUILD_PATH}" \
		-DSTB_IMAGE_INCLUDE_DIR=/usr/local/include/stb \
		-DCMAKE_PREFIX_PATH="/usr/local;${USD_BUILD_PATH}"; \
	cmake --build ufg/build -j"$(nproc)"; \
	cmake --install ufg/build --prefix "${CONVERTER_PREFIX}/ufg"; \
	rm -rf ufg; \
	\
	# --- gltfpack (meshoptimizer) --------------------------------------------
	# Built without Basis Universal: KTX2 encoding is handled by gltf-transform
	# and the ktx tool, so gltfpack is used for mesh optimisation only.
	git clone --branch "v${MESHOPTIMIZER_VERSION}" --depth 1 https://github.com/zeux/meshoptimizer meshoptimizer; \
	cmake -S meshoptimizer -B meshoptimizer/build \
		-DCMAKE_BUILD_TYPE=Release \
		-DMESHOPT_BUILD_GLTFPACK=ON \
		-DMESHOPT_INSTALL=OFF; \
	cmake --build meshoptimizer/build -j"$(nproc)" --target gltfpack; \
	install -m 0755 meshoptimizer/build/gltfpack "${CONVERTER_PREFIX}/bin/gltfpack"; \
	rm -rf meshoptimizer; \
	\
	# Strip binaries and drop development files from the install prefix.
	find "${CONVERTER_PREFIX}" -type f \( -perm -u+x -o -name '*.so*' \) -exec strip --strip-unneeded {} + 2>/dev/null || true; \
	rm -rf "${CONVERTER_PREFIX}/ufg/include" "${CONVERTER_PREFIX}/ufg/lib/cmake"

# USD's plugin loader reads plugInfo.json from each PXR_PLUGINPATH_NAME entry.
# UFG installs its own under plugin/usd/ufg_plugin/resources/, so add the same
# top-level include file OpenUSD uses for its plugin/usd directory. This lets
# PXR_PLUGINPATH_NAME point at plugin/usd and pick up any plugin placed there.
RUN printf '{\n    "Includes": [ "*/resources/" ]\n}\n' > "${CONVERTER_PREFIX}/ufg/plugin/usd/plugInfo.json"

# ===========================================================================
# Stage 2: runtime image.
# ===========================================================================
FROM ${BASE_IMAGE}

# Node.js LTS. https://nodejs.org/en/about/previous-releases
ARG NODE_VERSION=24.20.0
# KTX-Software. gltf-transform requires >= 4.4.0 (it calls `ktx create`).
ARG KTX_VERSION=4.4.2
# glTF Transform CLI. https://www.npmjs.com/package/@gltf-transform/cli
ARG GLTF_TRANSFORM_VERSION=4.5.0

LABEL org.opencontainers.image.title="converter-base"
LABEL org.opencontainers.image.description="OpenUSD + Apple AR schemas + usd_from_gltf + gltf-transform + KTX-Software + gltfpack + Node.js"
LABEL org.opencontainers.image.source="https://github.com/blippar-labs/usd-docker"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.vendor="Blippar Labs"

# USD_VERSION, USD_BUILD_PATH, USD_BIN_PATH, USD_LIB_PATH, USD_PLUGIN_PATH,
# PATH, LD_LIBRARY_PATH and PYTHONPATH are inherited from usd-base-ar.

ENV CONVERTER_PREFIX=/opt/converter
ENV UFG_PATH=${CONVERTER_PREFIX}/ufg
ENV UFG_BIN_PATH=${UFG_PATH}/bin
# Static libraries (libconvert.a etc.) for linking against ufg::ConvertGltfToUsd.
ENV UFG_LIB_PATH=${UFG_PATH}/lib/ufg
ENV UFG_PLUGIN_PATH=${UFG_PATH}/plugin/usd
ENV NODE_VERSION=${NODE_VERSION}
ENV KTX_VERSION=${KTX_VERSION}
ENV GLTF_TRANSFORM_VERSION=${GLTF_TRANSFORM_VERSION}

ENV PATH=${PATH}:${CONVERTER_PREFIX}/bin:${UFG_BIN_PATH}
# Register UFG's glTF SdfFileFormat plugin with USD's plugin loader, so
# Usd.Stage.Open("model.gltf") works from Python.
ENV PXR_PLUGINPATH_NAME=${PXR_PLUGINPATH_NAME:+${PXR_PLUGINPATH_NAME}:}${UFG_PLUGIN_PATH}

WORKDIR /usr/src/app

COPY --from=builder ${CONVERTER_PREFIX} ${CONVERTER_PREFIX}

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		# Runtime libraries UFG is linked against.
		libpng16-16t64 \
		libturbojpeg0 \
		libgif7 \
		zlib1g; \
	\
	# --- Node.js ---------------------------------------------------------------
	dpkg_arch="$(dpkg --print-architecture)"; \
	case "${dpkg_arch}" in \
		amd64) node_arch=x64;   ktx_arch=x86_64 ;; \
		arm64) node_arch=arm64; ktx_arch=arm64 ;; \
		*) echo "unsupported architecture: ${dpkg_arch}" >&2; exit 1 ;; \
	esac; \
	node_tar="node-v${NODE_VERSION}-linux-${node_arch}.tar.gz"; \
	curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${node_tar}"; \
	curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
	grep " ${node_tar}\$" SHASUMS256.txt | sha256sum -c -; \
	tar -xzf "${node_tar}" -C /usr/local --strip-components=1 --no-same-owner \
		--exclude='*/CHANGELOG.md' --exclude='*/LICENSE' --exclude='*/README.md'; \
	rm -f "${node_tar}" SHASUMS256.txt; \
	node --version; npm --version; \
	\
	# --- KTX-Software ----------------------------------------------------------
	ktx_deb="KTX-Software-${KTX_VERSION}-Linux-${ktx_arch}.deb"; \
	curl -fsSLO "https://github.com/KhronosGroup/KTX-Software/releases/download/v${KTX_VERSION}/${ktx_deb}"; \
	curl -fsSLO "https://github.com/KhronosGroup/KTX-Software/releases/download/v${KTX_VERSION}/${ktx_deb}.sha1"; \
	sha1sum -c "${ktx_deb}.sha1"; \
	dpkg -i "${ktx_deb}"; \
	rm -f "${ktx_deb}" "${ktx_deb}.sha1"; \
	# Drop the Java bindings and development files; only the CLI tools and
	# libktx are needed at runtime.
	rm -rf /usr/lib/libktx-jni* /usr/lib/libktx-*.jar /usr/lib/cmake/ktx /usr/include/ktx* /usr/include/KHR; \
	ktx --version; \
	\
	# --- gltf-transform --------------------------------------------------------
	npm install --global "@gltf-transform/cli@${GLTF_TRANSFORM_VERSION}"; \
	npm cache clean --force; \
	rm -rf /root/.npm /tmp/*; \
	gltf-transform --version; \
	\
	# --- cleanup ---------------------------------------------------------------
	apt-get purge -y curl; \
	apt-get autoremove -y; \
	apt-get autoclean -y; \
	rm -rf /var/lib/apt/lists/*; \
	\
	# --- sanity ----------------------------------------------------------------
	usd_from_gltf --version || usd_from_gltf --help >/dev/null; \
	gltfpack 2>&1 | head -n 1; \
	python3 -c "from pxr import Usd; print(Usd.GetVersion())"
