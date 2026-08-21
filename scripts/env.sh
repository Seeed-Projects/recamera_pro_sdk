#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TOOLCHAIN_ROOT="${SDK_ROOT}/toolchain/aarch64-rockchip1240-linux-gnu"
TOOLCHAIN_BIN="${TOOLCHAIN_ROOT}/bin"
TOOLCHAIN_FILE="${SDK_ROOT}/cmake/recamera-pro-toolchain.cmake"

# =========================================================
# SDK
# =========================================================

export RECAMERA_PRO_SDK="${SDK_ROOT}"

# =========================================================
# Toolchain
# =========================================================

export PATH="${TOOLCHAIN_BIN}:${PATH}"

export CC="aarch64-rockchip1240-linux-gnu-gcc"
export CXX="aarch64-rockchip1240-linux-gnu-g++"

export CROSS_COMPILE="aarch64-rockchip1240-linux-gnu-"

# Common names used by reCamera Pro build helpers.
export RECAMERA_SYSROOT="${SDK_ROOT}/sysroot"
export RECAMERA_CROSS_PREFIX="${TOOLCHAIN_BIN}/aarch64-rockchip1240-linux-gnu-"

# Keep pkg-config strictly inside the target sysroot.
export PKG_CONFIG_SYSROOT_DIR="${RECAMERA_SYSROOT}"
export PKG_CONFIG_LIBDIR="${RECAMERA_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig:${RECAMERA_SYSROOT}/usr/lib64/pkgconfig:${RECAMERA_SYSROOT}/usr/lib/pkgconfig:${RECAMERA_SYSROOT}/usr/share/pkgconfig"

# =========================================================
# CMake
# CMake >= 3.21 supports CMAKE_TOOLCHAIN_FILE environment variable.
# =========================================================

export CMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}"

# =========================================================
# Information
# =========================================================

echo "reCamera Pro SDK environment loaded"
echo
echo "SDK       : ${RECAMERA_PRO_SDK}"
echo "Toolchain : ${TOOLCHAIN_ROOT}"
echo "CC        : $(which ${CC})"
echo "CXX       : $(which ${CXX})"
echo "CMake TC  : ${CMAKE_TOOLCHAIN_FILE}"
echo "Sysroot   : ${RECAMERA_SYSROOT}"
echo
"${CC}" --version | head -1
