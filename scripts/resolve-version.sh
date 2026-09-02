#!/usr/bin/env bash
#
# Resolve an OpenUSD version string.
#
#   resolve-version.sh            -> prints the latest upstream release (e.g. 26.08)
#   resolve-version.sh latest     -> same as above
#   resolve-version.sh 26.05      -> prints 26.05 (validates the format)
#   resolve-version.sh v26.05     -> prints 26.05 (leading "v" is stripped)
#
# Set GITHUB_TOKEN (or GH_TOKEN) to avoid the anonymous GitHub API rate limit.

set -euo pipefail

requested="${1:-latest}"
api="https://api.github.com/repos/PixarAnimationStudios/OpenUSD/releases/latest"

if [[ "${requested}" == "latest" ]]; then
	token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
	if [[ -n "${token}" ]]; then
		body="$(curl -fsSL -H "Authorization: Bearer ${token}" -H "Accept: application/vnd.github+json" "${api}")"
	else
		body="$(curl -fsSL -H "Accept: application/vnd.github+json" "${api}")"
	fi
	tag="$(printf '%s' "${body}" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1)"
	if [[ -z "${tag}" ]]; then
		echo "error: could not resolve latest OpenUSD release from ${api}" >&2
		exit 1
	fi
	version="${tag#v}"
else
	version="${requested#v}"
fi

# OpenUSD releases are YY.MM, occasionally with a patch component (e.g. 23.11.1).
if [[ ! "${version}" =~ ^[0-9]{2}\.[0-9]{2}(\.[0-9]+)?$ ]]; then
	echo "error: '${version}' does not look like an OpenUSD version (expected YY.MM or YY.MM.N)" >&2
	exit 1
fi

echo "${version}"
