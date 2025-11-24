# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(opus_ffi_library VERSION 0.0.1 LANGUAGES C)

set(RUST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../rust")

if(ANDROID)
  add_library(opus_ffi SHARED IMPORTED)
  set_target_properties(opus_ffi PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}/libopus_ffi.so"
    IMPORTED_NO_SONAME TRUE
    PUBLIC_HEADER opus_ffi.h
  )
  # Support Android 15 16k page size
  target_link_options(opus_ffi INTERFACE "-Wl,-z,max-page-size=16384")
else()
  if(WIN32)
    set(RUST_LIB "${RUST_DIR}/target/release/opus_ffi.dll")
  elseif(APPLE)
    set(RUST_LIB "${RUST_DIR}/target/release/libopus_ffi.dylib")
  else()
    set(RUST_LIB "${RUST_DIR}/target/release/libopus_ffi.so")
  endif()

  add_custom_command(
    OUTPUT ${RUST_LIB}
    COMMAND cargo build --manifest-path ${RUST_DIR}/Cargo.toml --release
    WORKING_DIRECTORY ${RUST_DIR}
    BYPRODUCTS ${RUST_LIB}
    COMMENT "Building Rust opus_ffi library"
    VERBATIM
  )

  add_custom_target(opus_ffi_rust ALL DEPENDS ${RUST_LIB})

  add_library(opus_ffi SHARED IMPORTED)
  add_dependencies(opus_ffi opus_ffi_rust)
  set_target_properties(opus_ffi PROPERTIES
    IMPORTED_LOCATION ${RUST_LIB}
    IMPORTED_NO_SONAME TRUE
    PUBLIC_HEADER opus_ffi.h
  )
endif()
