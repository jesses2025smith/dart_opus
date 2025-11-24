#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
RUST_DIR="${PROJECT_ROOT}/rust"
SRC_DIR="${PROJECT_ROOT}/src"
BUILD_DIR="${PROJECT_ROOT}/build/apple"

ARCHS_VALUE="${ARCHS:-$(uname -m)}"
PLATFORM_NAME_VALUE="${PLATFORM_NAME:-macosx}"
CONFIGURATION_VALUE="${CONFIGURATION:-Release}"
EFFECTIVE_PLATFORM_VALUE="${EFFECTIVE_PLATFORM_NAME:-}"

echo "Building Rust library for platform: ${PLATFORM_NAME_VALUE}, arch: ${ARCHS_VALUE}"

if [[ "${PLATFORM_NAME_VALUE}" == "macosx" ]]; then
  case "${ARCHS_VALUE}" in
    arm64)
      TARGET_TRIPLE="aarch64-apple-darwin"
      LIB_NAME="libopus_ffi.dylib"
      ;;
    x86_64)
      TARGET_TRIPLE="x86_64-apple-darwin"
      LIB_NAME="libopus_ffi.dylib"
      ;;
    *)
      echo "Unsupported macOS arch: ${ARCHS_VALUE}"
      exit 1
      ;;
  esac

  export CARGO_BUILD_TARGET="${TARGET_TRIPLE}"
  BUILD_PATH="${BUILD_DIR}/${TARGET_TRIPLE}"
  mkdir -p "${BUILD_PATH}"

  cmake -S "${SRC_DIR}" -B "${BUILD_PATH}" -DCMAKE_BUILD_TYPE="${CONFIGURATION_VALUE}"
  cmake --build "${BUILD_PATH}" --target opus_ffi_rust

  OUTPUT_DIR="${PROJECT_ROOT}/macos/Libraries/${TARGET_TRIPLE}"
  mkdir -p "${OUTPUT_DIR}"
  cp "${RUST_DIR}/target/${TARGET_TRIPLE}/release/${LIB_NAME}" "${OUTPUT_DIR}/${LIB_NAME}"
else
  IOS_MIN_VERSION="${IOS_MIN_VERSION:-13.0}"
  export IPHONEOS_DEPLOYMENT_TARGET="${IOS_MIN_VERSION}"
  export IPHONESIMULATOR_DEPLOYMENT_TARGET="${IOS_MIN_VERSION}"

  case "${ARCHS_VALUE}" in
    arm64)
      if [[ "${EFFECTIVE_PLATFORM_VALUE}" == "-iphonesimulator" ]]; then
        TARGET_TRIPLE="aarch64-apple-ios-sim"
        IOS_VERSION_FLAG="-C link-arg=-mios-simulator-version-min=${IOS_MIN_VERSION}"
      else
        TARGET_TRIPLE="aarch64-apple-ios"
        IOS_VERSION_FLAG="-C link-arg=-miphoneos-version-min=${IOS_MIN_VERSION}"
      fi
      ;;
    x86_64)
      TARGET_TRIPLE="x86_64-apple-ios"
      IOS_VERSION_FLAG="-C link-arg=-mios-simulator-version-min=${IOS_MIN_VERSION}"
      ;;
    *)
      echo "Unsupported iOS arch: ${ARCHS_VALUE}"
      exit 1
      ;;
  esac

  rustup target add "${TARGET_TRIPLE}" >/dev/null 2>&1 || true
  cargo rustc \
    --manifest-path "${RUST_DIR}/Cargo.toml" \
    --release \
    --target "${TARGET_TRIPLE}" \
    -- \
    --crate-type staticlib \
    ${IOS_VERSION_FLAG}

  OUTPUT_DIR="${PROJECT_ROOT}/ios/Libraries/${TARGET_TRIPLE}"
  mkdir -p "${OUTPUT_DIR}"
  cp "${RUST_DIR}/target/${TARGET_TRIPLE}/release/libopus_ffi.a" "${OUTPUT_DIR}/libopus_ffi.a"
fi

