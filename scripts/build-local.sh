#!/usr/bin/env bash
#
# Build usd-base, usd-base-ar and converter-base locally for the host architecture.
#
#   scripts/build-local.sh            # latest upstream OpenUSD release
#   scripts/build-local.sh 26.05      # a specific release
#
# Images are tagged locally as usd-base:<version>, usd-base-ar:<version> and
# converter-base:<CONVERTER_VERSION> (default "dev").
#
#   IMAGE_PREFIX=ghcr.io/blippar-labs   tag under a registry namespace
#   ONLY=base|ar|converter              build a single image (later stages expect
#                                       the earlier ones to exist locally or in
#                                       the registry given by IMAGE_PREFIX)
#   CONVERTER_VERSION=1.3.0             tag for converter-base (default: dev)
#   BASE_IMAGE=<ref>                    with ONLY=converter, build on this exact
#                                       image instead of usd-base-ar:<version>
#
# Note: converter-base pins its own OpenUSD version in converter-base/Dockerfile.
# When building the full chain, the version given here is passed through so all
# three images line up; when it differs from the Dockerfile pin, the Dockerfile
# pin is what a tagged release will use.
#
# Expect an hour or more for the full chain: OpenUSD is compiled from source
# twice. converter-base alone takes a few minutes.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$("${repo_root}/scripts/resolve-version.sh" "${1:-latest}")"
prefix="${IMAGE_PREFIX:+${IMAGE_PREFIX}/}"
only="${ONLY:-}"
converter_version="${CONVERTER_VERSION:-dev}"

base_image="${prefix}usd-base:${version}"
ar_image="${prefix}usd-base-ar:${version}"
converter_image="${prefix}converter-base:${converter_version}"

echo "OpenUSD version: ${version}"

if [[ -z "${only}" || "${only}" == "base" ]]; then
	echo "==> building ${base_image}"
	docker build \
		--build-arg "USD_VERSION=${version}" \
		--tag "${base_image}" \
		--file "${repo_root}/usd-base/Dockerfile" \
		"${repo_root}/usd-base"
fi

if [[ -z "${only}" || "${only}" == "ar" ]]; then
	echo "==> building ${ar_image} (FROM ${base_image})"
	docker build \
		--build-arg "BASE_IMAGE=${base_image}" \
		--tag "${ar_image}" \
		--file "${repo_root}/usd-base-ar/Dockerfile" \
		"${repo_root}/usd-base-ar"
fi

if [[ -z "${only}" || "${only}" == "converter" ]]; then
	converter_base="${BASE_IMAGE:-${ar_image}}"
	echo "==> building ${converter_image} (FROM ${converter_base})"
	docker build \
		--build-arg "BASE_IMAGE=${converter_base}" \
		--tag "${converter_image}" \
		--file "${repo_root}/converter-base/Dockerfile" \
		"${repo_root}/converter-base"
fi

echo "done"
