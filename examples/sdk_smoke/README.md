# SDK smoke-test example / SDK 冒烟测试示例

This example verifies that a fresh SDK checkout can compile and link one C++17 program against RKNN Runtime, OpenCV, and GStreamer. On reCamera Pro it also executes a small OpenCV operation, runs a harmless in-memory GStreamer pipeline, and verifies that the RKNN Runtime can be loaded.

本示例用于确认新下载的 SDK 能够将一个 C++17 程序与 RKNN Runtime、OpenCV 和 GStreamer 完成交叉编译及链接。在 reCamera Pro 上运行时，它还会执行一次简单的 OpenCV 运算、一条无硬件占用的 GStreamer 内存流水线，并确认 RKNN Runtime 可以被动态加载。

From the SDK root / 在 SDK 根目录执行：

```bash
source scripts/env.sh
mkdir -p examples/sdk_smoke/build
cd examples/sdk_smoke/build
cmake ..
make -j"$(nproc)"
```

This bundled example also selects the SDK toolchain automatically. If this
build directory was previously configured with `/usr/bin/c++`, remove its
CMake cache once and configure again:

本仓库示例也会自动选择 SDK toolchain。如果这个 build 目录此前已经被
`/usr/bin/c++` 配置过，请删除一次 CMake 缓存后重新配置：

```bash
rm -rf CMakeCache.txt CMakeFiles
cmake ..
make -j"$(nproc)"
```

Inspect the executable / 检查编译产物：

```bash
file recamera_sdk_smoke
"${CROSS_COMPILE}readelf" -d recamera_sdk_smoke | grep -E 'NEEDED|RPATH|RUNPATH'
```

Deploy and run / 部署并运行：

```bash
scp recamera_sdk_smoke root@192.168.42.1:/tmp/
ssh root@192.168.42.1 /tmp/recamera_sdk_smoke
```

Expected final line / 预期最后一行：

```text
ALL CHECKS PASSED
```
