#!/bin/bash
set -e

# Define paths
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUST_DIR="$PROJECT_ROOT/rust"
IOS_LIB_DIR="$PROJECT_ROOT/ios/Libraries"
HEADER_DIR="$PROJECT_ROOT/ios/Classes"
FRAMEWORK_DIR="$IOS_LIB_DIR/opus_ffi.xcframework"

# Copy generated C header
echo "Copying C header..."
mkdir -p "$HEADER_DIR"
if [[ -f "$RUST_DIR/include/opus_ffi.h" ]]; then
    cp "$RUST_DIR/include/opus_ffi.h" "$HEADER_DIR/opus_ffi.h"
else
    echo "Error: $RUST_DIR/include/opus_ffi.h not found. Ensure cargo build has run."
    exit 1
fi

# Paths to artifacts built by build_apple.sh
ARM64_DEVICE="$IOS_LIB_DIR/aarch64-apple-ios/libopus_ffi.a"
ARM64_SIM="$IOS_LIB_DIR/aarch64-apple-ios-sim/libopus_ffi.a"
X86_64_SIM="$IOS_LIB_DIR/x86_64-apple-ios/libopus_ffi.a"

# Check if artifacts exist
if [[ ! -f "$ARM64_DEVICE" ]]; then
    echo "Error: $ARM64_DEVICE not found. Run build_apple.sh first."
    exit 1
fi

# Create a temporary directory for the simulator fat binary
SIM_FAT_DIR="$IOS_LIB_DIR/simulator_fat"
mkdir -p "$SIM_FAT_DIR"
SIM_FAT_LIB="$SIM_FAT_DIR/libopus_ffi.a"

echo "Creating Simulator Fat Binary..."
# Lipo the simulator architectures
if [[ -f "$ARM64_SIM" && -f "$X86_64_SIM" ]]; then
    lipo -create "$ARM64_SIM" "$X86_64_SIM" -output "$SIM_FAT_LIB"
elif [[ -f "$X86_64_SIM" ]]; then
    cp "$X86_64_SIM" "$SIM_FAT_LIB"
elif [[ -f "$ARM64_SIM" ]]; then
    cp "$ARM64_SIM" "$SIM_FAT_LIB"
else
    echo "Error: No simulator binaries found."
    exit 1
fi

# Create XCFramework
echo "Creating XCFramework..."
rm -rf "$FRAMEWORK_DIR"

xcodebuild -create-xcframework \
    -library "$ARM64_DEVICE" \
    -headers "$HEADER_DIR" \
    -library "$SIM_FAT_LIB" \
    -headers "$HEADER_DIR" \
    -output "$FRAMEWORK_DIR"

echo "XCFramework created at $FRAMEWORK_DIR"

# Cleanup
rm -rf "$SIM_FAT_DIR"
