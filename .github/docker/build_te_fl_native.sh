#!/usr/bin/env bash

set -euo pipefail

: "${TE_FL_REPO:?TE_FL_REPO is required}"
: "${OUTPUT_DIR:?OUTPUT_DIR is required}"

python_bin="${CI_PYTHON_BIN:-$(command -v python3)}"
if [ ! -x "$python_bin" ]; then
  echo "::error::TE-FL Python executable not found: $python_bin" >&2
  exit 1
fi

if [ ! -f "$TE_FL_REPO/pyproject.toml" ]; then
  echo "::error::TE-FL source is missing pyproject.toml: $TE_FL_REPO" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
find "$OUTPUT_DIR" -maxdepth 1 -type f -name 'transformer_engine*.whl' -delete

echo "Building TransformerEngine-FL wheel from $TE_FL_REPO"
# NVTE_PLUGIN and NVTE_PLUGIN_SKIP_CUDA=1 are required when building the new
# two-repo layout (TransformerEngine interface + TransformerEngine-Plugin-FL).
# NVTE_PLUGIN activates the plugin-only code path in setup.py; without it
# NVTE_PLUGIN_SKIP_CUDA is ignored and the build falls through to the CUDA
# toolchain (which is absent on non-CUDA platforms).
NVTE_PLUGIN="${NVTE_PLUGIN:-transformer_engine_plugin_fl}" \
NVTE_PLUGIN_SKIP_CUDA=1 \
"$python_bin" -m pip wheel \
  --no-deps \
  --no-build-isolation \
  --no-cache-dir \
  --wheel-dir "$OUTPUT_DIR" \
  "$TE_FL_REPO"

mapfile -t wheels < <(
  find "$OUTPUT_DIR" -maxdepth 1 -type f -name 'transformer_engine*.whl' -print | sort
)
if [ "${#wheels[@]}" -ne 1 ]; then
  echo "::error::Expected exactly one TransformerEngine-FL wheel, found ${#wheels[@]}" >&2
  printf '  %s\n' "${wheels[@]}" >&2
  exit 1
fi

echo "TE-FL wheel ready: ${wheels[0]}"
