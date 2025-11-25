# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "opus_ffi")
project(${PROJECT_NAME} LANGUAGES CXX)

# Install the prebuilt library
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/opus_ffi.dll" DESTINATION "${CMAKE_INSTALL_PREFIX}")

set(opus_ffi_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/opus_ffi.dll"
  PARENT_SCOPE
)
