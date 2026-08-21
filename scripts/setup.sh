#!/usr/bin/env bash
set -euo pipefail

readonly SDK_VERSION="v1.0.0"
readonly REPOSITORY="Seeed-Projects/recamera_pro_sdk"
readonly TOOLCHAIN_ARCHIVE="recamera-pro-toolchain-${SDK_VERSION}.tar.xz"
readonly SYSROOT_ARCHIVE="recamera-pro-sysroot-${SDK_VERSION}.tar.xz"
readonly TOOLCHAIN_SHA256="5046b6669883cc009663c0bd344cadabac9073a26d49ca112251514135d2cee0"
readonly SYSROOT_SHA256="f57847f13fa467d7403e2faee568f5baad79268cda9efe4733c413b79d25a701"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RELEASE_BASE_URL="${RECAMERA_RELEASE_BASE_URL:-https://github.com/${REPOSITORY}/releases/download/${SDK_VERSION}}"

for command_name in curl sha256sum tar xz mktemp; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "error: required command not found: ${command_name}" >&2
        exit 1
    fi
done

toolchain_ok() {
    local compiler="${SDK_ROOT}/toolchain/aarch64-rockchip1240-linux-gnu/bin/aarch64-rockchip1240-linux-gnu-gcc"
    [ -x "${compiler}" ] && [ "$("${compiler}" -dumpmachine 2>/dev/null)" = "aarch64-rockchip1240-linux-gnu" ]
}

sysroot_ok() {
    local runtime="${SDK_ROOT}/sysroot/usr/lib/librknnrt.so"
    [ -f "${runtime}" ] && [ "$(sha256sum "${runtime}" | awk '{print $1}')" = "d31fc19c85b85f6091b2bd0f6af9d962d5264a4e410bfb536402ec92bac738e8" ]
}

if toolchain_ok && sysroot_ok; then
    echo "reCamera Pro SDK ${SDK_VERSION} is already installed."
    exit 0
fi

if [ -e "${SDK_ROOT}/toolchain" ] || [ -e "${SDK_ROOT}/sysroot" ]; then
    echo "error: an incomplete or incompatible toolchain/sysroot already exists." >&2
    echo "Move or remove both directories, then run scripts/setup.sh again." >&2
    exit 1
fi

SETUP_DIR="$(mktemp -d "${SDK_ROOT}/.setup.XXXXXX")"
trap 'rm -rf "${SETUP_DIR}"' EXIT INT TERM

download_and_verify() {
    local archive_name="$1"
    local expected_sha256="$2"
    local archive_path="${SETUP_DIR}/${archive_name}"

    echo "Downloading ${archive_name}..."
    curl -fL --retry 3 --retry-delay 2 \
        "${RELEASE_BASE_URL}/${archive_name}" \
        -o "${archive_path}"
    printf '%s  %s\n' "${expected_sha256}" "${archive_path}" | sha256sum --check --status
    echo "Verified ${archive_name}"
}

download_and_verify "${TOOLCHAIN_ARCHIVE}" "${TOOLCHAIN_SHA256}"
download_and_verify "${SYSROOT_ARCHIVE}" "${SYSROOT_SHA256}"

mkdir "${SETUP_DIR}/extract"
tar -xJf "${SETUP_DIR}/${TOOLCHAIN_ARCHIVE}" -C "${SETUP_DIR}/extract"
tar -xJf "${SETUP_DIR}/${SYSROOT_ARCHIVE}" -C "${SETUP_DIR}/extract"

test -x "${SETUP_DIR}/extract/toolchain/aarch64-rockchip1240-linux-gnu/bin/aarch64-rockchip1240-linux-gnu-gcc"
printf '%s  %s\n' \
    "d31fc19c85b85f6091b2bd0f6af9d962d5264a4e410bfb536402ec92bac738e8" \
    "${SETUP_DIR}/extract/sysroot/usr/lib/librknnrt.so" | sha256sum --check --status

mv "${SETUP_DIR}/extract/toolchain" "${SDK_ROOT}/toolchain"
mv "${SETUP_DIR}/extract/sysroot" "${SDK_ROOT}/sysroot"

bash "${SDK_ROOT}/scripts/check-sdk.sh"
echo "reCamera Pro SDK ${SDK_VERSION} installation complete."
echo "Run: source scripts/env.sh"
