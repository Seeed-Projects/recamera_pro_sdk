set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# =========================================================
# SDK Root
# =========================================================

get_filename_component(
    SDK_ROOT
    "${CMAKE_CURRENT_LIST_DIR}/.."
    ABSOLUTE
)

# =========================================================
# Toolchain
# =========================================================

set(
    TOOLCHAIN_ROOT
    "${SDK_ROOT}/toolchain/aarch64-rockchip1240-linux-gnu"
)

set(
    TOOLCHAIN_SYSROOT
    "${TOOLCHAIN_ROOT}/aarch64-rockchip1240-linux-gnu/sysroot"
)

set(
    RECAMERA_SYSROOT
    "${SDK_ROOT}/sysroot"
)

# pkg-config is a host tool, but it must only resolve target metadata. Keep
# this here as well as in scripts/env.sh so an explicitly selected toolchain
# works in a fresh shell and from IDEs.
set(ENV{PKG_CONFIG_SYSROOT_DIR} "${RECAMERA_SYSROOT}")
set(ENV{PKG_CONFIG_LIBDIR}
    "${RECAMERA_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig:${RECAMERA_SYSROOT}/usr/lib64/pkgconfig:${RECAMERA_SYSROOT}/usr/lib/pkgconfig:${RECAMERA_SYSROOT}/usr/share/pkgconfig"
)

# =========================================================
# Compiler
# =========================================================

set(
    CMAKE_C_COMPILER
    "${TOOLCHAIN_ROOT}/bin/aarch64-rockchip1240-linux-gnu-gcc"
)

set(
    CMAKE_CXX_COMPILER
    "${TOOLCHAIN_ROOT}/bin/aarch64-rockchip1240-linux-gnu-g++"
)

# =========================================================
# CMake Search Paths
#
# reCamera sysroot:
#   OpenCV / RKNN / RGA / device libraries
#
# Toolchain sysroot:
#   glibc / libstdc++ / crt / system runtime
# =========================================================

set(
    CMAKE_FIND_ROOT_PATH
    "${RECAMERA_SYSROOT}"
    "${TOOLCHAIN_SYSROOT}"
)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Produce deployable build-tree binaries. CMake otherwise adds absolute sysroot
# directories to RPATH when target libraries are linked by full path.
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH "/oem/usr/lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

# =========================================================
# Linker
#
# Allow linker to resolve indirect dependencies of device
# libraries such as OpenCV.
# =========================================================

set(
    RECAMERA_RPATH_LINK_FLAGS
    "-Wl,-rpath-link,${RECAMERA_SYSROOT}/lib \
     -Wl,-rpath-link,${RECAMERA_SYSROOT}/lib64 \
     -Wl,-rpath-link,${RECAMERA_SYSROOT}/usr/lib \
     -Wl,-rpath-link,${RECAMERA_SYSROOT}/usr/lib64"
)

set(
    CMAKE_EXE_LINKER_FLAGS_INIT
    "${RECAMERA_RPATH_LINK_FLAGS}"
)

set(
    CMAKE_SHARED_LINKER_FLAGS_INIT
    "${RECAMERA_RPATH_LINK_FLAGS}"
)

set(
    CMAKE_MODULE_LINKER_FLAGS_INIT
    "${RECAMERA_RPATH_LINK_FLAGS}"
)
