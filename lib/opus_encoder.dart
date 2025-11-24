import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'opus_error.dart';
import 'opus_ffi.dart';
import 'opus_ffi_bindings_generated.dart';
import 'opus_utils.dart';

/// Opus 编码器封装类
class OpusEncoder {
  Pointer<Encoder>? _encoder;
  final Channels channels;
  final int sampleRate;
  final Application application;

  /// 创建新的 Opus 编码器
  ///
  /// [channels] 声道数：1 表示单声道（Mono），2 表示立体声（Stereo）
  /// [sampleRate] 采样率（Hz），支持的采样率：8000, 12000, 16000, 24000, 48000
  /// [application] 应用模式，默认为 [Application.voip]
  ///
  /// 抛出 [OpusException] 如果创建失败
  OpusEncoder({
    required this.channels,
    required this.sampleRate,
    this.application = Application.voip,
  }) {
    final result = calloc<Pointer<Encoder>>();
    final error = calloc<OpusError>();

    try {
      final res = bindings.new_encoder(
        channels.value,
        sampleRate,
        application.value,
        result,
        error,
      );

      if (res != 0) {
        final errorMsg = extractErrorMessage(error);
        throw OpusException(error.ref.code, errorMsg);
      }

      _encoder = result.value;
    } finally {
      freeError(error);
      calloc.free(result);
    }
  }

  /// 将 PCM 样本编码为 Opus 数据包（16 位整数输入）
  ///
  /// [input] PCM 样本数据（16 位有符号整数）
  /// [inputSize] 输入样本的数量（不是字节数）。对于单声道，这是样本数；对于立体声，这是样本对的数量
  ///
  /// 返回编码后的 Opus 数据包
  /// 抛出 [OpusException] 如果编码失败
  Uint8List encode(Int16List input, {int? inputSize}) {
    if (_encoder == null) {
      throw StateError('Encoder has been disposed');
    }

    final size = inputSize ?? input.length;
    final output = calloc<Uint8>(4000); // Opus 数据包最大约为 4000 字节
    final encodedSize = calloc<UintPtr>();
    final error = calloc<OpusError>();

    try {
      final inputPtr = calloc<Int16>(size);
      inputPtr.asTypedList(size).setAll(0, input);

      final res = bindings.encode(
        _encoder!,
        inputPtr,
        size,
        output,
        4000,
        encodedSize,
        error,
      );

      calloc.free(inputPtr);

      if (res != 0) {
        final errorMsg = extractErrorMessage(error);
        throw OpusException(error.ref.code, errorMsg);
      }

      final encodedLen = encodedSize.value;
      final result = Uint8List(encodedLen);
      final outputList = output.asTypedList(encodedLen);
      result.setAll(0, outputList);

      return result;
    } finally {
      freeError(error);
      calloc.free(output);
      calloc.free(encodedSize);
    }
  }

  /// 将 PCM 样本编码为 Opus 数据包（32 位浮点数输入）
  ///
  /// [input] PCM 样本数据（32 位浮点数，范围通常在 [-1.0, 1.0] 之间）
  /// [inputSize] 输入样本的数量（不是字节数）
  ///
  /// 返回编码后的 Opus 数据包
  /// 抛出 [OpusException] 如果编码失败
  Uint8List encodeFloat(Float32List input, {int? inputSize}) {
    if (_encoder == null) {
      throw StateError('Encoder has been disposed');
    }

    final size = inputSize ?? input.length;
    final output = calloc<Uint8>(4000);
    final encodedSize = calloc<UintPtr>();
    final error = calloc<OpusError>();

    try {
      final inputPtr = calloc<Float>(size);
      inputPtr.asTypedList(size).setAll(0, input);

      final res = bindings.encode_float(
        _encoder!,
        inputPtr,
        size,
        output,
        4000,
        encodedSize,
        error,
      );

      calloc.free(inputPtr);

      if (res != 0) {
        final errorMsg = extractErrorMessage(error);
        throw OpusException(error.ref.code, errorMsg);
      }

      final encodedLen = encodedSize.value;
      final result = Uint8List(encodedLen);
      final outputList = output.asTypedList(encodedLen);
      result.setAll(0, outputList);

      return result;
    } finally {
      freeError(error);
      calloc.free(output);
      calloc.free(encodedSize);
    }
  }

  /// 释放编码器资源
  void dispose() {
    if (_encoder != null) {
      bindings.free_encoder(_encoder!);
      _encoder = null;
    }
  }
}
