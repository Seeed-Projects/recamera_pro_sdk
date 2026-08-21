cmake_minimum_required(VERSION 3.16)

# This example is part of the SDK, so select its toolchain before project().
# It therefore also works when CMAKE_TOOLCHAIN_FILE was not inherited from a
# sourced environment (for example from an IDE or a new terminal).
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    get_filename_component(RECAMERA_SDK_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
    set(CMAKE_TOOLCHAIN_FILE
        "${RECAMERA_SDK_ROOT}/cmake/recamera-pro-toolchain.cmake"
        CACHE FILEPATH "reCamera Pro cross-compilation toolchain"
    )
endif()

project(recamera_sdk_smoke LANGUAGES CXX)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTREAMER REQUIRED IMPORTED_TARGET
    gstreamer-1.0
    gstreamer-app-1.0
)

set(RECAMERA_OPENCV_LIB_DIR "${RECAMERA_SYSROOT}/usr/lib")

add_executable(recamera_sdk_smoke main.cpp)
target_compile_features(recamera_sdk_smoke PRIVATE cxx_std_17)
target_include_directories(recamera_sdk_smoke PRIVATE
    "${RECAMERA_SYSROOT}/usr/include"
    "${RECAMERA_SYSROOT}/usr/include/opencv4"
)
target_link_libraries(recamera_sdk_smoke PRIVATE
    "${RECAMERA_SYSROOT}/usr/lib/librknnrt.so"
    "${RECAMERA_OPENCV_LIB_DIR}/libopencv_core.so"
    "${RECAMERA_OPENCV_LIB_DIR}/libopencv_imgproc.so"
    PkgConfig::GSTREAMER
)

message(STATUS "reCamera sysroot: ${RECAMERA_SYSROOT}")
message(STATUS "Target processor: ${CMAKE_SYSTEM_PROCESSOR}")
