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

### Apple (iOS/macOS)

通过 CocoaPods 的脚本阶段调用 `tool/build_apple.sh`，根据当前编译架构自动调度：

```bash
ARCHS=arm64 PLATFORM_NAME=macosx tool/build_apple.sh
ARCHS=arm64 PLATFORM_NAME=iphoneos tool/build_apple.sh
ARCHS=x86_64 PLATFORM_NAME=iphonesimulator EFFECTIVE_PLATFORM_NAME=-iphonesimulator tool/build_apple.sh
```

- 在 macOS 平台下脚本会使用 `src/CMakeLists.txt` 驱动 `cargo build` 并生成 `.dylib`。
- 在 iOS 平台下脚本会针对目标三元组编译静态库 `.a` 并复制到 `ios/Libraries/<target>/`。

### 发布到 pub.dev

发布前请确保所有二进制已经生成：

1. Android：执行 `cargo ndk --platform 21 --target aarch64-linux-android --target x86_64-linux-android --release`，并拷贝到 `android/src/main/jniLibs/<abi>/`。
2. macOS / iOS：依次运行 `tool/build_apple.sh`（详见上文），确保 `macos/Libraries/**` 与 `ios/Libraries/**` 下存在对应架构的库文件。

Git 仓库会忽略这些产物，但 `.pubignore` 允许它们被打包，因此在运行 `flutter pub publish` 之前无需手动调整忽略规则。
