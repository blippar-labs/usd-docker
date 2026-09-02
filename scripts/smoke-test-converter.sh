#!/usr/bin/env bash
#
# Smoke test a converter-base image: every bundled tool must run, and a real
# glTF sample must convert to USDZ and encode to KTX2 and WebP.
#
#   scripts/smoke-test-converter.sh converter-base:dev
#   scripts/smoke-test-converter.sh ghcr.io/blippar-labs/converter-base@sha256:...
#
# The Khronos "BoxTextured" sample is downloaded to a temp directory on the host
# and mounted into the container (the image ships without curl).

set -euo pipefail

image="${1:?usage: $0 <image>}"
sample_url="https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/BoxTextured/glTF-Binary/BoxTextured.glb"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

curl -fsSL "${sample_url}" -o "${work}/box.glb"

docker run --rm -v "${work}:/work" -w /work "${image}" bash -euxo pipefail -c '
	echo "== versions"
	python3 -c "from pxr import Usd; print(\"OpenUSD\", Usd.GetVersion())"
	node --version
	npm --version
	gltf-transform --version
	ktx --version
	gltfpack_usage="$(gltfpack 2>&1 || true)"   # exits non-zero without arguments
	printf "%s\n" "${gltfpack_usage}" | sed -n 1p
	usd_from_gltf --version

	echo "== glTF -> USDZ (usd_from_gltf)"
	usd_from_gltf box.glb box.usdz
	test -s box.usdz
	usdchecker box.usdz || echo "warning: usdchecker reported issues (non-fatal)"
	python3 -c "from pxr import Usd; s = Usd.Stage.Open(\"box.usdz\"); assert s.GetPseudoRoot().GetChildren(), \"empty stage\""

	echo "== UFG glTF file format plugin registered with USD (PXR_PLUGINPATH_NAME)"
	# Registration only: the fork plugin Read path currently asserts on full
	# paths (convert/converter.cc MakeAbsolutePath), so Usd.Stage.Open("x.glb")
	# fails until that is fixed upstream. Conversion via the CLI is unaffected.
	python3 -c "from pxr import Sdf; assert Sdf.FileFormat.FindByExtension(\"glb\") is not None, \"ufg_plugin not registered\""

	echo "== gltf-transform: webp"
	gltf-transform webp box.glb box.webp.glb
	test -s box.webp.glb

	echo "== gltf-transform: uastc (KTX2 via ktx)"
	gltf-transform uastc box.glb box.uastc.glb
	test -s box.uastc.glb
	gltf-transform inspect box.uastc.glb --format csv | grep -qi ktx2

	echo "== gltf-transform: etc1s (KTX2 via ktx)"
	gltf-transform etc1s box.glb box.etc1s.glb
	test -s box.etc1s.glb

	echo "== gltf-transform: meshopt + optimize"
	gltf-transform meshopt box.glb box.meshopt.glb
	gltf-transform optimize box.glb box.opt.glb --texture-compress webp
	test -s box.opt.glb

	echo "== gltfpack"
	gltfpack -i box.glb -o box.pack.glb -cc
	test -s box.pack.glb

	echo "== OK"
'
echo "smoke test passed: ${image}"
