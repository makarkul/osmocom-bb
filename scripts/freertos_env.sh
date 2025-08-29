#!/usr/bin/env bash
# Source this inside the container to setup build environment for osmocom-bb-freertos
# This builds HOST applications (Layer23) to run on FreeRTOS instead of Linux

set -euo pipefail

# Ensure PKG_CONFIG_PATH defined before we append (avoid set -u unbound variable)
: "${PKG_CONFIG_PATH:=}"

ROOT_DIR=${ROOT_DIR:-/workspace}
FREERTOS_DEPS_DIR=${FREERTOS_DEPS_DIR:-$ROOT_DIR/deps/freertos}
LIBOSMOCORE_DIR=${LIBOSMOCORE_DIR:-$ROOT_DIR/deps/libosmocore}
LOCAL_LIBOSMOCORE_ALT=$ROOT_DIR/src/shared/libosmocore

# Setup PKG_CONFIG_PATH for in-tree libosmocore (FreeRTOS adapted) if present
if [ -d "$LOCAL_LIBOSMOCORE_ALT" ]; then
	export PKG_CONFIG_PATH="$LOCAL_LIBOSMOCORE_ALT/build-freertos/src:$LOCAL_LIBOSMOCORE_ALT/build-freertos:$PKG_CONFIG_PATH"
fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Compiler setup - using standard GCC for host applications targeting FreeRTOS
export CC=${CC:-gcc}
export AR=${AR:-ar}

# FreeRTOS include paths for host applications
export FREERTOS_CFLAGS="-I$FREERTOS_DEPS_DIR/config -I$FREERTOS_DEPS_DIR/include/kernel -I$FREERTOS_DEPS_DIR/include/tcp -I$FREERTOS_DEPS_DIR/include/portable/GCC/POSIX"

# FreeRTOS target flags (host apps running on FreeRTOS)
export FREERTOS_TARGET_CFLAGS="-DTARGET_FREERTOS=1 -DFREERTOS_HOST=1"

# libosmocore include paths 
if [ -d "$LOCAL_LIBOSMOCORE_ALT/build-freertos/include" ]; then
	export LIBOSMOCORE_CFLAGS="-I$LOCAL_LIBOSMOCORE_ALT/build-freertos/include ${LIBOSMOCORE_CFLAGS:-}"
	export LIBOSMOCORE_LIBS="-L$LOCAL_LIBOSMOCORE_ALT/build-freertos/src/.libs ${LIBOSMOCORE_LIBS:-}"
else
	export LIBOSMOCORE_CFLAGS="-I/usr/local/include"
	export LIBOSMOCORE_LIBS="-L/usr/local/lib"
fi

# Combined CFLAGS and LDFLAGS for building host apps to run on FreeRTOS
export CFLAGS="$FREERTOS_CFLAGS $FREERTOS_TARGET_CFLAGS $LIBOSMOCORE_CFLAGS ${CFLAGS:-}"
export LDFLAGS="$LIBOSMOCORE_LIBS ${LDFLAGS:-}"

# Configure arguments for host applications targeting FreeRTOS
export HOST_CONFARGS="--enable-freertos"

# Target flags
export TARGET_FREERTOS=1

# osmocom-bb-freertos specific environment
export OSMO_BB_FREERTOS=1

echo "[freertos_env] Environment setup for host applications targeting FreeRTOS"
echo "[freertos_env] Building Layer23 (mobile) to run on FreeRTOS instead of Linux"
echo "[freertos_env] Compiler: $CC"
echo "[freertos_env] CFLAGS=$CFLAGS"
echo "[freertos_env] LDFLAGS=$LDFLAGS"
echo "[freertos_env] Configure args: $HOST_CONFARGS"
echo "[freertos_env] Ready for building host applications for FreeRTOS target"