## Opus FFI

该插件通过 Rust 提供 Opus 编解码能力，并在 Dart 中通过 FFI 调用。构建时需要自动编译 Rust 动态库，请确保本地已安装：

- Rust（含 `cargo`）
- [`cargo-ndk`](https://github.com/bbqsrc/cargo-ndk)（`cargo install cargo-ndk`）
- Android NDK（Flutter 工程会自动传入 `ndkVersion`）

### Android

插件的 `android/build.gradle` 已集成 `cargo ndk`。当宿主应用执行 `preBuild` 时，会自动运行：

```bash
cargo ndk --platform 21 --target aarch64-linux-android --target x86_64-linux-android --release
```

生成的 `libopus_ffi.so` 会复制到 `android/src/main/jniLibs/<abi>/`，无需额外手动步骤。

### 桌面平台

Linux / Windows / macOS 会通过 CMake 触发 `cargo build --release` 并将产物作为插件库导出。确保执行 `flutter build` 或桌面端调试时，系统 PATH 中可以找到 `cargo`。
