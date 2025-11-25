#!/bin/bash
set -e

# Define paths
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUST_DIR="$PROJECT_ROOT/rust"
IOS_LIB_DIR="$PROJECT_ROOT/ios/Libraries"
MACOS_LIB_DIR="$PROJECT_ROOT/macos/Libraries"
HEADER_DIR="$PROJECT_ROOT/ios/Classes"
IOS_FRAMEWORK_DIR="$IOS_LIB_DIR/opus_ffi.xcframework"
MACOS_FRAMEWORK_DIR="$MACOS_LIB_DIR/opus_ffi.xcframework"

# Copy generated C header
echo "Copying C header..."
mkdir -p "$HEADER_DIR"
if [[ -f "$RUST_DIR/include/opus_ffi.h" ]]; then
    cp "$RUST_DIR/include/opus_ffi.h" "$HEADER_DIR/opus_ffi.h"
else
    echo "Error: $RUST_DIR/include/opus_ffi.h not found. Ensure cargo build has run."
    exit 1
fi

# ============================================
# iOS XCFramework
# ============================================
echo "Creating iOS XCFramework..."

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

echo "Creating iOS Simulator Fat Binary..."
# Lipo the simulator architectures
if [[ -f "$ARM64_SIM" && -f "$X86_64_SIM" ]]; then
    lipo -create "$ARM64_SIM" "$X86_64_SIM" -output "$SIM_FAT_LIB"
elif [[ -f "$X86_64_SIM" ]]; then
    cp "$X86_64_SIM" "$SIM_FAT_LIB"
elif [[ -f "$ARM64_SIM" ]]; then
    cp "$ARM64_SIM" "$SIM_FAT_LIB"
else
    echo "Error: No iOS simulator binaries found."
    exit 1
fi

# Create iOS XCFramework
rm -rf "$IOS_FRAMEWORK_DIR"
xcodebuild -create-xcframework \
    -library "$ARM64_DEVICE" \
    -headers "$HEADER_DIR" \
    -library "$SIM_FAT_LIB" \
    -headers "$HEADER_DIR" \
    -output "$IOS_FRAMEWORK_DIR"

echo "iOS XCFramework created at $IOS_FRAMEWORK_DIR"

# Cleanup
rm -rf "$SIM_FAT_DIR"

# ============================================
# macOS XCFramework
# ============================================
echo "Creating macOS XCFramework..."

# Paths to macOS artifacts
ARM64_MACOS="$MACOS_LIB_DIR/aarch64-apple-darwin/libopus_ffi.dylib"
X86_64_MACOS="$MACOS_LIB_DIR/x86_64-apple-darwin/libopus_ffi.dylib"

# Create universal binary for macOS
UNIVERSAL_DIR="$MACOS_LIB_DIR/universal"
mkdir -p "$UNIVERSAL_DIR"
UNIVERSAL_LIB="$UNIVERSAL_DIR/libopus_ffi.dylib"

echo "Creating macOS Universal Binary..."
if [[ -f "$ARM64_MACOS" && -f "$X86_64_MACOS" ]]; then
    lipo -create "$ARM64_MACOS" "$X86_64_MACOS" -output "$UNIVERSAL_LIB"
elif [[ -f "$X86_64_MACOS" ]]; then
    cp "$X86_64_MACOS" "$UNIVERSAL_LIB"
elif [[ -f "$ARM64_MACOS" ]]; then
    cp "$ARM64_MACOS" "$UNIVERSAL_LIB"
else
    echo "Error: No macOS binaries found."
    exit 1
fi

# Create macOS XCFramework
rm -rf "$MACOS_FRAMEWORK_DIR"
xcodebuild -create-xcframework \
    -library "$UNIVERSAL_LIB" \
    -headers "$HEADER_DIR" \
    -output "$MACOS_FRAMEWORK_DIR"

echo "macOS XCFramework created at $MACOS_FRAMEWORK_DIR"

# Cleanup
rm -rf "$UNIVERSAL_DIR"

echo "All XCFrameworks created successfully!"
