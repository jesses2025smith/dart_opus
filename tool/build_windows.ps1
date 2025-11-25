$ErrorActionPreference = "Stop"

# Build the Rust library using GNU toolchain
Set-Location rust
cargo build --release --target x86_64-pc-windows-gnu
Set-Location ..

# Create the windows directory if it doesn't exist
New-Item -ItemType Directory -Force -Path windows

# Copy the shared library
# MinGW might prefix with 'lib' or not, checking both just in case, but usually it respects crate name for cdylib
# However, standard convention for windows-gnu is often lib<name>.dll
if (Test-Path rust/target/x86_64-pc-windows-gnu/release/opus_ffi.dll) {
    Copy-Item rust/target/x86_64-pc-windows-gnu/release/opus_ffi.dll -Destination windows/opus_ffi.dll
} elseif (Test-Path rust/target/x86_64-pc-windows-gnu/release/libopus_ffi.dll) {
    Copy-Item rust/target/x86_64-pc-windows-gnu/release/libopus_ffi.dll -Destination windows/opus_ffi.dll
} else {
    Write-Error "Could not find built DLL in rust/target/x86_64-pc-windows-gnu/release/"
}
