#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Checking reCamera Pro SDK..."

check()
{
    if [ -e "$1" ]; then
        echo "[OK] $1"
    else
        echo "[MISS] $1"
        exit 1
    fi
}

TOOLCHAIN_BIN="${ROOT}/toolchain/aarch64-rockchip1240-linux-gnu/bin"
CC="${TOOLCHAIN_BIN}/aarch64-rockchip1240-linux-gnu-gcc"
CXX="${TOOLCHAIN_BIN}/aarch64-rockchip1240-linux-gnu-g++"

check "${CC}"
check "${CXX}"

check "${ROOT}/sysroot/usr/include/rknn_api.h"

check "${ROOT}/sysroot/usr/lib/librknnrt.so"

check "${ROOT}/sysroot/usr/include/opencv4/opencv2/core.hpp"

check "${ROOT}/sysroot/usr/lib/libopencv_core.so"
check "${ROOT}/sysroot/usr/lib/libopencv_imgproc.so"
check "${ROOT}/sysroot/usr/lib/libopencv_imgcodecs.so"

EXPECTED_RKNNRT_SHA256="d31fc19c85b85f6091b2bd0f6af9d962d5264a4e410bfb536402ec92bac738e8"
ACTUAL_RKNNRT_SHA256="$(sha256sum "${ROOT}/sysroot/usr/lib/librknnrt.so" | awk '{print $1}')"
if [ "${ACTUAL_RKNNRT_SHA256}" != "${EXPECTED_RKNNRT_SHA256}" ]; then
    echo "[FAIL] librknnrt.so checksum mismatch"
    exit 1
fi
echo "[OK] librknnrt.so SHA-256"

if [ "$("${CC}" -dumpmachine)" != "aarch64-rockchip1240-linux-gnu" ]; then
    echo "[FAIL] unexpected compiler target: $("${CC}" -dumpmachine)"
    exit 1
fi
echo "[OK] compiler target: aarch64-rockchip1240-linux-gnu"

PKG_CONFIG_SYSROOT_DIR="${ROOT}/sysroot" \
PKG_CONFIG_LIBDIR="${ROOT}/sysroot/usr/lib/aarch64-linux-gnu/pkgconfig:${ROOT}/sysroot/usr/lib64/pkgconfig:${ROOT}/sysroot/usr/lib/pkgconfig:${ROOT}/sysroot/usr/share/pkgconfig" \
    pkg-config --exists gstreamer-1.0 gstreamer-app-1.0 glib-2.0
echo "[OK] target GStreamer and GLib pkg-config metadata"

echo
echo "SDK looks good."
