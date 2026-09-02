# syntax=docker/dockerfile:1.7

# usd-base-ar: usd-base plus Apple's "Preliminary_" AR schemas
#
# Apple's USDZ Schemas for AR addendum defines Preliminary_AnchoringAPI,
# Preliminary_Behavior, Preliminary_Trigger, Preliminary_Action,
# Preliminary_ReferenceImage and Preliminary_Text. They are not part of upstream
# OpenUSD, so they are code-generated with usdGenSchema and compiled into the
# USD install inherited from usd-base.
#
# BASE_IMAGE must be a usd-base image. The OpenUSD version is taken from the
# USD_VERSION environment variable exported by that image, so the schemas are
# always compiled against exactly the version the base was built with.
#
# Apple schemas: https://developer.apple.com/documentation/arkit/usdz_schemas_for_ar
ARG BASE_IMAGE=ghcr.io/blippar-labs/usd-base:latest
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="usd-base-ar"
LABEL org.opencontainers.image.description="Pixar OpenUSD with Apple's Preliminary_* AR schemas compiled in"
LABEL org.opencontainers.image.source="https://github.com/blippar-labs/usd-docker"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.vendor="Blippar Labs"

# USD_VERSION, USD_BUILD_PATH, USD_BIN_PATH, USD_LIB_PATH, USD_PLUGIN_PATH,
# PATH, LD_LIBRARY_PATH and PYTHONPATH are inherited from usd-base.

ENV USD_SCHEMA_FOLDER=usd_schemas

WORKDIR /usr/src/app

COPY ${USD_SCHEMA_FOLDER}/ /usr/src/app/${USD_SCHEMA_FOLDER}/

RUN set -eux; \
	test -n "${USD_VERSION}"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		git \
		ca-certificates \
		build-essential \
		cmake \
		nasm \
		libxrandr-dev \
		libxcursor-dev \
		libxinerama-dev \
		libxi-dev; \
	rm -rf /var/lib/apt/lists/*; \
	git clone --branch "v${USD_VERSION}" --depth 1 https://github.com/PixarAnimationStudios/OpenUSD.git usdsrc; \
	# Drop the Apple schema package into the OpenUSD source tree.
	cp -a "/usr/src/app/${USD_SCHEMA_FOLDER}/usdInteractive/" usdsrc/pxr/usd/; \
	# Generate C++/Python sources from schema.usda using the usdGenSchema
	# inherited from usd-base, then register the package with CMake.
	(cd usdsrc/pxr/usd/usdInteractive && usdGenSchema schema.usda .); \
	echo "add_subdirectory(usdInteractive)" >> usdsrc/pxr/usd/CMakeLists.txt; \
	# Rebuild USD into the same prefix. Third-party dependencies already present
	# in the prefix are detected and skipped by build_usd.py.
	# PXR_PYTHON_INSTALL_DIR must match usd-base so the bindings stay at
	# lib/python (OpenUSD 26.08 defaults to lib/pythonX.Y/site-packages).
	python3 usdsrc/build_scripts/build_usd.py \
		--build-args USD,"-DPXR_PYTHON_INSTALL_DIR=lib/python" \
		--no-examples \
		--no-tutorials \
		--no-imaging \
		--no-usdview \
		--no-draco \
		--no-materialx \
		"${USD_BUILD_PATH}"; \
	rm -rf usdsrc; \
	rm -rf "/usr/src/app/${USD_SCHEMA_FOLDER}"; \
	python3 -c "from pxr import Usd, UsdInteractive; print(Usd.GetVersion())"; \
	rm -rf \
		"${USD_BUILD_PATH}/build" \
		"${USD_BUILD_PATH}/share" \
		"${USD_BUILD_PATH}/src"; \
	apt-get purge -y \
		git \
		build-essential \
		cmake \
		nasm \
		libxrandr-dev \
		libxcursor-dev \
		libxinerama-dev \
		libxi-dev; \
	apt-get autoremove -y; \
	apt-get autoclean -y; \
	rm -rf /var/lib/apt/lists/*
