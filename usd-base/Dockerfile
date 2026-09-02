# syntax=docker/dockerfile:1.7

# usd-base: pre-compiled Pixar OpenUSD toolchain
#
# OpenUSD takes a long time to compile and is released infrequently, so it is
# built once here and consumed as a base layer by the other images in this
# repository (for example usd-base-ar) and by downstream projects.
#
# The CMake package configuration (pxrConfig.cmake, cmake/) is deliberately
# kept so that derived images can compile USD plugins against this install.
#
# OpenUSD: https://github.com/PixarAnimationStudios/OpenUSD
ARG PYTHON_BASE=python:3.12-slim-trixie
FROM ${PYTHON_BASE}

# OpenUSD version to build. Override with --build-arg USD_VERSION=26.08
# (the value is the upstream release tag without the leading "v").
ARG USD_VERSION=26.08
ENV USD_VERSION=${USD_VERSION}

LABEL org.opencontainers.image.title="usd-base"
LABEL org.opencontainers.image.description="Pre-built Pixar OpenUSD toolchain with Python bindings"
LABEL org.opencontainers.image.source="https://github.com/blippar-labs/usd-docker"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.vendor="Blippar Labs"

# OpenUSD install layout. Derived images and tools rely on these variables.
ENV USD_BUILD_PATH=/usr/src/app/xrutils/usd
ENV USD_PLUGIN_PATH=${USD_BUILD_PATH}/plugin/usd
ENV USD_BIN_PATH=${USD_BUILD_PATH}/bin
ENV USD_LIB_PATH=${USD_BUILD_PATH}/lib
ENV PATH=${PATH}:${USD_BIN_PATH}
ENV LD_LIBRARY_PATH=${USD_LIB_PATH}
ENV PYTHONPATH=${USD_LIB_PATH}/python

WORKDIR /usr/src/app

RUN set -eux; \
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
	# Jinja2 is needed by usdGenSchema; numpy enables the pxr.Vt array bindings.
	pip3 install --no-cache-dir --upgrade Jinja2 numpy; \
	mkdir -p xrutils; \
	git clone --branch "v${USD_VERSION}" --depth 1 https://github.com/PixarAnimationStudios/OpenUSD.git usdsrc; \
	# PXR_PYTHON_INSTALL_DIR keeps the Python bindings at lib/python. OpenUSD
	# 26.08 changed the default to lib/pythonX.Y/site-packages; older releases
	# ignore the variable (it is only an unused-variable CMake warning there).
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
	# The bindings must be importable via the PYTHONPATH exported above;
	# derived images (usdGenSchema in usd-base-ar) depend on it.
	python3 -c "from pxr import Usd; print(Usd.GetVersion())"; \
	# Drop intermediate build artifacts. pxrConfig.cmake and cmake/ are kept on
	# purpose so derived images can build plugins against this install.
	rm -rf \
		"${USD_BUILD_PATH}/build" \
		"${USD_BUILD_PATH}/share" \
		"${USD_BUILD_PATH}/src"; \
	# Remove build-only OS packages. Derived images reinstall what they need.
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
