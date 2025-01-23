#!/bin/bash
# Copyright Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
# The script is used to build libffi for Linux.

set -e

# If ARM64 architecture and clang exists, set clang as the compiler
CLANG_PATH=$(which clang)
CLANGPP_PATH=$(which clang++)

if [ "$(uname -m)" == "aarch64" ] && [ "$CLANG_PATH" ] && [ "$CLANGPP_PATH" ]; then
    export CC=$CLANG_PATH
    export CXX=$CLANGPP_PATH
fi 

# Get the directory where the script is located
HOME_PATH=$(cd $(dirname $0); pwd)
BUILD_DIR=${HOME_PATH}/libffi/build
OUTPUT_DIR=${HOME_PATH}/libffi/output

# libffi repository and version
LIBFFI_REPO="szv-open.codehub.huawei.com:2222/OpenSourceCenter/openEuler/libffi.git"
LIBFFI_TAG="3.4.2-8.oe2203sp3"  # You can modify the version as needed
LIBFFI_ROOT_PATH=${HOME_PATH}/libffi/third_party/libffi
LIBFFI_SRC_PATH=${LIBFFI_ROOT_PATH}/libffi-${LIBFFI_TAG}

# Patch path (if needed)
PATCH_DIR=${HOME_PATH}/patch
LIBFFI_PATCH="${PATCH_DIR}/libffi-fix.patch"

# Parse script arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --libffi_root_path=*)
      LIBFFI_ROOT_PATH="${1#*=}"
      ;;
    --output_dir=*)
      OUTPUT_DIR="${1#*=}"
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
  esac
  shift
done

# If the libffi source directory does not exist, clone the repository
if [ ! -d "${LIBFFI_ROOT_PATH}" ]; then
    git clone -b ${LIBFFI_TAG} ${LIBFFI_REPO} ${LIBFFI_ROOT_PATH}
fi

# If the libffi source code is not extracted, extract and apply patches
if [ ! -d "${LIBFFI_SRC_PATH}" ]; then
    tar -zxf ${LIBFFI_ROOT_PATH}/libffi-${LIBFFI_TAG}.tar.gz -C ${LIBFFI_ROOT_PATH}
    # If there is a patch to apply, uncomment the following line and add the patch path
    if [ -f "${LIBFFI_PATCH}" ]; then
        patch -p1 -d ${LIBFFI_SRC_PATH} < ${LIBFFI_PATCH}
    fi
fi

# Create and enter the build directory
if [ -d "${BUILD_DIR}" ]; then
    rm -r ${BUILD_DIR}
fi
mkdir -p ${BUILD_DIR} && cd ${BUILD_DIR}

# Configure and build libffi
cmake ${LIBFFI_SRC_PATH} -DCMAKE_INSTALL_PREFIX=${OUTPUT_DIR} -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_SYSTEM_NAME=Linux # Specify Linux as the target platform

# Build the project
make -j

# Install libffi to the output directory
make install 

echo "libffi has been successfully built and installed to ${OUTPUT_DIR}"