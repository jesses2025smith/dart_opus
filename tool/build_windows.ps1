$ErrorActionPreference = "Stop"

# Build the Rust library
Set-Location rust
cargo build --release
Set-Location ..

# Create the windows directory if it doesn't exist
New-Item -ItemType Directory -Force -Path windows

# Copy the shared library
Copy-Item rust/target/release/opus_ffi.dll -Destination windows/
