#!/usr/bin/env bash
#
# Build usd-base and then usd-base-ar locally for the host architecture.
#
#   scripts/build-local.sh            # latest upstream OpenUSD release
#   scripts/build-local.sh 26.05      # a specific release
#
# Images are tagged locally as usd-base:<version> and usd-base-ar:<version>.
# Set IMAGE_PREFIX to tag them under a registry namespace instead, e.g.
#   IMAGE_PREFIX=ghcr.io/blippar-labs scripts/build-local.sh 26.08
# Set ONLY=base or ONLY=ar to build a single image (ONLY=ar expects the base to exist).
#
# Expect an hour or more: OpenUSD is compiled from source twice.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$("${repo_root}/scripts/resolve-version.sh" "${1:-latest}")"
prefix="${IMAGE_PREFIX:+${IMAGE_PREFIX}/}"
only="${ONLY:-}"

base_image="${prefix}usd-base:${version}"
ar_image="${prefix}usd-base-ar:${version}"

echo "OpenUSD version: ${version}"

if [[ "${only}" != "ar" ]]; then
	echo "==> building ${base_image}"
	docker build \
		--build-arg "USD_VERSION=${version}" \
		--tag "${base_image}" \
		--file "${repo_root}/usd-base/Dockerfile" \
		"${repo_root}/usd-base"
fi

if [[ "${only}" != "base" ]]; then
	echo "==> building ${ar_image} (FROM ${base_image})"
	docker build \
		--build-arg "BASE_IMAGE=${base_image}" \
		--tag "${ar_image}" \
		--file "${repo_root}/usd-base-ar/Dockerfile" \
		"${repo_root}/usd-base-ar"
fi

echo "done"
