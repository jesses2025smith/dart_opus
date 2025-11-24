import 'dart:ffi';
import 'dart:io';

import 'opus_ffi_bindings_generated.dart';

const String _libName = 'opus_ffi';

/// The dynamic library in which the symbols for [OpusFfiBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final OpusFfiBindings _bindings = OpusFfiBindings(_dylib);

/// 获取 FFI bindings 实例（供内部使用）
OpusFfiBindings get bindings => _bindings;

enum Channels {
  /// 单声道
  mono(1),

  /// 立体声
  stereo(2);

  final int value;
  const Channels(this.value);
}

/// Opus 应用模式
enum Application {
  /// Voip（语音通话，低延迟优化）
  voip(1),

  /// Audio（音频流，高质量优化）
  audio(2),

  /// LowDelay（低延迟模式）
  lowDelay(3);

  final int value;
  const Application(this.value);
}
