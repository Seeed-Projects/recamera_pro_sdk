# reCamera Pro 交叉编译 SDK

[English](README.md)

![reCamera Pro](https://files.seeedstudio.com/wiki/reCamera-Pro/Secondary_Development/reCamera_pro_sdk/product-hero.png)

本仓库用于安装面向 **Seeed reCamera Pro**（`RV1126B`、`aarch64`）的自包含 C/C++ 交叉编译 SDK。Git 仓库只保存构建集成和示例；`scripts/setup.sh` 会从对应的 GitHub Release 下载版本固定的 Rockchip GCC 12.4 工具链和目标 sysroot。

> 本 SDK 只适用于 reCamera **Pro**，不适用于 SG2002/riscv64 版本的 reCamera。

### 平台约定

- 目标平台：Seeed reCamera Pro / Rockchip RV1126B / 64 位 ARM Linux
- 编译器：`aarch64-rockchip1240-linux-gnu-gcc` 12.4.0
- ELF 解释器：`/lib/ld-linux-aarch64.so.1`
- RKNN API 与 Runtime：2.3.2
- 设备端 RKNN Runtime：`/oem/usr/lib/librknnrt.so`
- GStreamer 开发 ABI：1.22
- CMake：建议 3.21 或更高版本，以便通过环境变量选择 toolchain

模型转换不属于本 SDK 的职责。在 x86_64 主机上使用 RKNN-Toolkit2 2.3.2，并设置 `target_platform='rv1126b'` 将 ONNX 转换成 RKNN；本仓库用于编译设备端 C/C++ 应用。

### 快速开始

Linux 或 WSL 主机需要安装：

```bash
sudo apt install cmake ninja-build pkg-config
```

下载并校验 v1.0.0 SDK 资产，然后加载环境：

```bash
./scripts/setup.sh
source scripts/env.sh
bash scripts/check-sdk.sh
```

安装脚本可重复执行，解压前会验证 SHA-256。Release 资产会安装为 `toolchain/` 和 `sysroot/`，这两个生成目录不会提交到 Git。

环境脚本会导出 `CC`、`CXX`、`CROSS_COMPILE`、`CMAKE_TOOLCHAIN_FILE`、`RECAMERA_SYSROOT`、`RECAMERA_CROSS_PREFIX`，并把 `pkg-config` 限制在目标 sysroot 内。

配置并构建 CMake 工程：

```bash
cmake -S . -B build -G Ninja
cmake --build build
```

也可以不加载环境，显式传入 toolchain 文件：

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/cmake/recamera-pro-toolchain.cmake"
cmake --build build
```

### 最小 CMake 接入示例

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

仓库提供的 toolchain 文件只会把 `/oem/usr/lib` 写入运行时搜索路径，不应把 SDK、构建目录或 WSL 的绝对路径写入目标程序。

### 构建仓库内的冒烟测试

[`examples/sdk_smoke`](examples/sdk_smoke) 工程会同时链接 RKNN Runtime、OpenCV 和 GStreamer，可以直接使用标准的 CMake Makefiles 流程构建：

```bash
source scripts/env.sh
mkdir -p examples/sdk_smoke/build
cd examples/sdk_smoke/build
cmake ..
make -j"$(nproc)"
```

部署方法和预期输出请参阅 [`examples/sdk_smoke/README.md`](examples/sdk_smoke/README.md)。
仓库内示例会自动选择 SDK toolchain。如果现有 build 目录曾使用宿主编译器配置，
请先删除一次 `CMakeCache.txt` 和 `CMakeFiles/`，再重新执行 `cmake ..`。

把产物推送到recamere pro之后运行，运行结果应该为:

![reCamera Pro](https://files.seeedstudio.com/wiki/reCamera-Pro/Secondary_Development/reCamera_pro_sdk/o3ET6sUxuM.jpg)

### 检查编译产物

```bash
file build/my_recamera_app
"${CROSS_COMPILE}readelf" -l build/my_recamera_app | grep interpreter
"${CROSS_COMPILE}readelf" -d build/my_recamera_app | grep -E 'NEEDED|RPATH|RUNPATH'
```

预期结果：

- 架构为 `ARM aarch64`，不是 x86-64 或 RISC-V
- 解释器为 `/lib/ld-linux-aarch64.so.1`
- `NEEDED` 中包含应用使用的目标库
- 运行时搜索路径为 `/oem/usr/lib`，不包含主机绝对路径

部署时只复制你的应用及其资源，不要覆盖设备上的 `/oem/usr/lib/librknnrt.so`。SDK 内的 Runtime 仅用于链接，并已与生产设备版本进行一致性校验。

### 仓库结构

```text
cmake/       CMake 交叉编译 toolchain 文件
scripts/     环境加载与 SDK 自检脚本
sysroot/     reCamera Pro 目标端头文件和库
toolchain/   Rockchip aarch64 GCC/binutils 工具链（由 setup.sh 安装）
examples/    示例工程
```

### 摄像头与模型输入

摄像头采集应使用 GStreamer。设备节点和插件随固件变化，硬编码前请先检查目标设备。已知生产固件的摄像头探测命令为：

```bash
gst-launch-1.0 -v v4l2src device=/dev/video13 num-buffers=30 \
  ! 'video/x-raw,format=NV12,width=1920,height=1080,framerate=30/1' \
  ! videoconvert ! fakesink
```

不要把 NV12 数据直接传给 RGB/BGR 模型。流水线必须输出模型要求的颜色格式和尺寸，并按模型文档实现 resize 或 letterbox 策略。

### 开源与再分发注意事项

本仓库包含第三方编译器、C 运行库、多媒体库、计算机视觉库和专有 RKNN 组件，各组件原有的许可证和声明仍然有效。公开发布或再分发前，请检查 `toolchain/**/share/licenses/` 下的许可证，保留必要声明并履行源代码提供义务，同时确认 `sysroot/` 内每个二进制文件都允许再分发。仓库级许可证不能替代第三方许可证。

安装后的 SDK 约为 2.5 GB。工具链和 sysroot 通过带版本号的 GitHub Release 压缩包分发，因此 Git 中只保存源码和集成文件。`scripts/setup.sh` 会保留符号链接并校验发布包的 SHA-256。

### 已知限制

- 交叉编译成功只能证明编译和链接通过，不能证明模型精度或设备端运行正确。
- 摄像头节点、GStreamer 插件、音频设备、编码器和 RTSP 组件可能随固件变化。
- 当前 sysroot 的 libc 暴露到 GLIBC 2.38；若目标设备使用不同固件，发布兼容性声明前必须核对实际 ABI。
- 不要使用其他开发板、包管理器或 RKNN Model Zoo 中的 RKNN Runtime 替换本 SDK 的版本。
