#!/bin/bash
set -e

# Build the Rust library
cd rust
cargo build --release
cd ..

# Create the linux directory if it doesn't exist
mkdir -p linux

# Copy the shared library
cp rust/target/release/libopus_ffi.so linux/
