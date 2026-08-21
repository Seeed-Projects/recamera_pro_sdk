# reCamera Pro Cross-Compilation SDK

[简体中文](README-CN.md)

![reCamera Pro](https://files.seeedstudio.com/wiki/reCamera-Pro/Secondary_Development/reCamera_pro_sdk/product-hero.png)

This repository installs a self-contained C/C++ cross-compilation SDK for **Seeed reCamera Pro** (`RV1126B`, `aarch64`). The Git repository contains the build integration and examples; `scripts/setup.sh` downloads the versioned Rockchip GCC 12.4 toolchain and target sysroot from the matching GitHub Release.

> This SDK targets reCamera **Pro** only. It does not target the SG2002/riscv64 reCamera.

### Platform contract

- Target: Seeed reCamera Pro / Rockchip RV1126B / 64-bit ARM Linux
- Compiler: `aarch64-rockchip1240-linux-gnu-gcc` 12.4.0
- ELF interpreter: `/lib/ld-linux-aarch64.so.1`
- RKNN API and Runtime: 2.3.2
- Device RKNN Runtime: `/oem/usr/lib/librknnrt.so`
- GStreamer development ABI: 1.22
- CMake: 3.21 or newer is recommended for environment-based toolchain selection

Model conversion is deliberately outside the scope of this SDK. Convert ONNX models with RKNN-Toolkit2 2.3.2 and `target_platform='rv1126b'` on an x86_64 host; use this repository to compile the target C/C++ application.

### Quick start

Prerequisites on the Linux or WSL host:

```bash
sudo apt install cmake ninja-build pkg-config
```

Download and verify the v1.0.0 SDK assets, then load the environment:

```bash
./scripts/setup.sh
source scripts/env.sh
bash scripts/check-sdk.sh
```

The setup is idempotent and validates SHA-256 before extracting. Release assets are installed as `toolchain/` and `sysroot/`; these generated directories are intentionally excluded from Git.

The environment exports `CC`, `CXX`, `CROSS_COMPILE`, `CMAKE_TOOLCHAIN_FILE`, `RECAMERA_SYSROOT`, `RECAMERA_CROSS_PREFIX`, and target-only `pkg-config` paths.

Configure and build a CMake project:

```bash
cmake -S . -B build -G Ninja
cmake --build build
```

Alternatively, do not source the environment and pass the toolchain explicitly:

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/cmake/recamera-pro-toolchain.cmake"
cmake --build build
```

### Minimal CMake integration

```cmake
cmake_minimum_required(VERSION 3.16)
project(my_recamera_app LANGUAGES C CXX)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTREAMER REQUIRED IMPORTED_TARGET
  gstreamer-1.0 gstreamer-app-1.0)

add_executable(my_recamera_app main.cpp)
target_include_directories(my_recamera_app PRIVATE
  "${RECAMERA_SYSROOT}/usr/include")
target_link_libraries(my_recamera_app PRIVATE
  "${RECAMERA_SYSROOT}/usr/lib/librknnrt.so"
  PkgConfig::GSTREAMER)
```

The supplied toolchain file embeds only `/oem/usr/lib` as the runtime search path. It must not embed an SDK, build-tree, or WSL absolute path.

### Build the included smoke test

The [`examples/sdk_smoke`](examples/sdk_smoke) project links RKNN Runtime, OpenCV, and GStreamer and can be built with the standard CMake Makefiles flow:

```bash
source scripts/env.sh
mkdir -p examples/sdk_smoke/build
cd examples/sdk_smoke/build
cmake ..
make -j"$(nproc)"
```

See [`examples/sdk_smoke/README.md`](examples/sdk_smoke/README.md) for deployment and expected output.
The bundled example selects the SDK toolchain automatically. For an existing
build directory previously configured with a host compiler, delete
`CMakeCache.txt` and `CMakeFiles/` once before running `cmake ..` again.

After pushing the product to Recamere Pro and running it, the expected result should be:

![reCamera Pro](https://files.seeedstudio.com/wiki/reCamera-Pro/Secondary_Development/reCamera_pro_sdk/o3ET6sUxuM.jpg)

### Verify an output binary

```bash
file build/my_recamera_app
"${CROSS_COMPILE}readelf" -l build/my_recamera_app | grep interpreter
"${CROSS_COMPILE}readelf" -d build/my_recamera_app | grep -E 'NEEDED|RPATH|RUNPATH'
```

Expected results:

- `ARM aarch64`, not x86-64 or RISC-V
- interpreter `/lib/ld-linux-aarch64.so.1`
- the expected target libraries in `NEEDED`
- runtime path `/oem/usr/lib`, with no host absolute paths

Copy only your application and its own assets to the device. Do **not** overwrite `/oem/usr/lib/librknnrt.so`; the SDK runtime is a link-time copy qualified against the production device runtime.

### Repository layout

```text
cmake/       CMake cross-compilation toolchain file
scripts/     environment loader and SDK validator
sysroot/     reCamera Pro target headers and libraries
toolchain/   Rockchip aarch64 GCC/binutils toolchain (installed by setup.sh)
examples/    example projects
```

### Camera and model input

Use GStreamer for capture. Device nodes and plugins are firmware-specific; inspect the target before hard-coding them. A known production camera probe is:

```bash
gst-launch-1.0 -v v4l2src device=/dev/video13 num-buffers=30 \
  ! 'video/x-raw,format=NV12,width=1920,height=1080,framerate=30/1' \
  ! videoconvert ! fakesink
```

Do not pass NV12 bytes directly to an RGB/BGR model. Make the pipeline output the model's exact color format and dimensions, and implement the model's documented resize or letterbox policy.

### Open-source and redistribution notes

This repository contains third-party compiler, C library, multimedia, computer-vision, and proprietary RKNN components. Their upstream licenses and notices remain applicable. Before publishing or redistributing the repository, review the license files under `toolchain/**/share/licenses/`, retain required notices and source-offer obligations, and confirm that every binary copied into `sysroot/` may be redistributed. A project-level license does not replace third-party licenses.

The installed SDK is approximately 2.5 GB. The toolchain and sysroot are distributed as versioned GitHub Release archives so Git only stores source and integration files. `scripts/setup.sh` preserves symlinks and verifies the published archive checksums.

### Limitations

- A successful cross-build verifies compilation and linkage, not model accuracy or on-device runtime behavior.
- Camera nodes, GStreamer plugins, audio devices, encoders, and RTSP components vary by firmware.
- The bundled target libc exposes symbols through GLIBC 2.38; validate the actual production firmware ABI before claiming compatibility with a different firmware image.
- Do not replace the SDK RKNN Runtime with a library from another board, package manager, or RKNN Model Zoo.
