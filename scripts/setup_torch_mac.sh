#!/usr/bin/env bash
set -euo pipefail

echo "[pix2pix setup] Starting Torch7 environment setup for macOS"

# Detect architecture (arm64 vs x86_64)
ARCH=$(uname -m)
TORCH_DIR="${HOME}/torch"

if ! command -v th >/dev/null 2>&1; then
  echo "[pix2pix setup] Torch not found. Cloning & installing into ${TORCH_DIR}"
  if [ ! -d "${TORCH_DIR}" ]; then
    git clone https://github.com/torch/distro.git "${TORCH_DIR}" --recursive
  fi
  pushd "${TORCH_DIR}" >/dev/null
  bash install-deps || true
  ./install.sh -b
  popd >/dev/null
else
  echo "[pix2pix setup] Torch already installed: $(command -v th)"
fi

if ! command -v luarocks >/dev/null 2>&1; then
  echo "[pix2pix setup] ERROR: luarocks not found in PATH after Torch install." >&2
  echo "Add ${TORCH_DIR}/install/bin to your PATH (e.g., echo 'export PATH=\"${TORCH_DIR}/install/bin:$PATH\"' >> ~/.zshrc)" >&2
  exit 1
fi

echo "[pix2pix setup] Installing required LuaRocks packages (CPU-safe)"
CPU_ONLY=0
if [ "${ARCH}" = "arm64" ]; then
  # Apple Silicon has no official CUDA, force CPU
  CPU_ONLY=1
fi

REQ_PACKAGES=(image nn optim paths nngraph)
OPTIONAL_GPU_PACKAGES=(cunn cudnn cutorch)

for pkg in "${REQ_PACKAGES[@]}"; do
  if ! luarocks list --porcelain | grep -q "^${pkg} "; then
    echo "[pix2pix setup] Installing ${pkg}"
    luarocks install "${pkg}" || true
  else
    echo "[pix2pix setup] ${pkg} already installed"
  fi
done

if [ ${CPU_ONLY} -eq 0 ]; then
  echo "[pix2pix setup] Attempting to install GPU related packages"
  for pkg in "${OPTIONAL_GPU_PACKAGES[@]}"; do
    if ! luarocks list --porcelain | grep -q "^${pkg} "; then
      echo "[pix2pix setup] Installing ${pkg} (best effort)"
      luarocks install "${pkg}" || echo "[pix2pix setup] Skipping ${pkg} (install failed)"
    else
      echo "[pix2pix setup] ${pkg} already installed"
    fi
  done
else
  echo "[pix2pix setup] Apple Silicon / CPU-only mode: skipping CUDA rocks (cunn, cudnn, cutorch)"
fi

echo "[pix2pix setup] (Optional) Installing display package for live visualization"
if ! luarocks list --porcelain | grep -q '^display '; then
  luarocks install https://raw.githubusercontent.com/szym/display/master/display-scm-0.rockspec || echo "[pix2pix setup] display install failed (optional)"
fi

echo "[pix2pix setup] Done. Open a new shell or ensure PATH includes ${TORCH_DIR}/install/bin"
echo "[pix2pix setup] Quick test: th -e 'print(require(\"nn\"))'"
