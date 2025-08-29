#!/usr/bin/env bash
set -euo pipefail

# Environment setup for Linux platform builds of osmocom-bb.

export PS1="(osmocom-bb-linux) ${PS1:-}" 2>/dev/null || true

export MAKEFLAGS="-j$(nproc)"
export PATH="/usr/local/bin:$PATH"

echo "[linux_env] Build environment configured."
echo "[linux_env] libosmocore version: $(pkg-config --modversion libosmocore 2>/dev/null || echo 'unknown')"

# Helpful hints
cat <<'EOT'
Examples:
  cd src/host/layer23
  autoreconf -fi
  ./configure --enable-mme --enable-transceiver CFLAGS="-O2" || cat config.log
  make -j$(nproc) mobile

To build firmware (if toolchains added later):
  cd src/target/firmware
  make BOARD=compal_e88
EOT
