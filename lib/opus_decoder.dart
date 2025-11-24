import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'opus_error.dart';
import 'opus_ffi.dart';
import 'opus_ffi_bindings_generated.dart';
import 'opus_utils.dart';

/// Opus 解码器封装类
class OpusDecoder {
  Pointer<Decoder>? _decoder;
  final Channels channels;
  final int sampleRate;

  /// 创建新的 Opus 解码器
  ///
  /// [channels] 声道数：1 表示单声道（Mono），2 表示立体声（Stereo）
  /// [sampleRate] 采样率（Hz），支持的采样率：8000, 12000, 16000, 24000, 48000
  ///
  /// 抛出 [OpusException] 如果创建失败
  OpusDecoder({required this.channels, required this.sampleRate}) {
    final result = calloc<Pointer<Decoder>>();
    final error = calloc<OpusError>();

    try {
      final res = bindings.new_decoder(
        channels.value,
        sampleRate,
        result,
        error,
      );

      if (res != 0) {
        final errorMsg = extractErrorMessage(error);
        throw OpusException(error.ref.code, errorMsg);
      }

      _decoder = result.value;
    } finally {
      freeError(error);
      calloc.free(result);
    }
  }

  /// 解码 Opus 音频数据包为 PCM 样本（16 位整数）
  ///
  /// [input] Opus 编码数据包
  /// [fec] 前向纠错标志，如果为 true，解码器将尝试使用前一个数据包来恢复丢失的数据
  ///
  /// 返回解码后的 PCM 样本（16 位有符号整数）
  /// 抛出 [OpusException] 如果解码失败
  Int16List decode(Uint8List input, {bool fec = false}) {
    if (_decoder == null) {
      throw StateError('Decoder has been disposed');
    }

    // 估算输出缓冲区大小：对于 16kHz 采样率，20ms 的帧需要至少 320 个样本
    // 使用更大的缓冲区以确保足够
    final maxSamples = (sampleRate * channels.value * 0.12).ceil(); // 120ms 的样本
    final output = calloc<Int16>(maxSamples);
    final decodedSize = calloc<UintPtr>();
    final error = calloc<OpusError>();

    try {
      final inputPtr = calloc<Uint8>(input.length);
      inputPtr.asTypedList(input.length).setAll(0, input);

      final res = bindings.decode(
        _decoder!,
        inputPtr,
        input.length,
        output,
        maxSamples,
        fec,
        decodedSize,
        error,
      );

      calloc.free(inputPtr);

      if (res != 0) {
        final errorMsg = extractErrorMessage(error);
        throw OpusException(error.ref.code, errorMsg);
      }

      final size = decodedSize.value;
      final result = Int16List(size);
      final outputList = output.asTypedList(size);
      result.setAll(0, outputList);

      return result;
    } finally {
      freeError(error);
      calloc.free(output);
      calloc.free(decodedSize);
    }
  }

  /// 解码 Opus 音频数据包为 PCM 样本（32 位浮点数）
  ///
  /// [input] Opus 编码数据包
  /// [fec] 前向纠错标志
  ///
  /// 返回解码后的浮点 PCM 样本（范围通常在 [-1.0, 1.0] 之间）
  /// 抛出 [OpusException] 如果解码失败
  Float32List decodeFloat(Uint8List input, {bool fec = false}) {
    if (_decoder == null) {
      throw StateError('Decoder has been disposed');
    }

    final maxSamples = (sampleRate * channels.value * 0.12).ceil();
    final output = calloc<Float>(maxSamples);
    final decodedSize = calloc<UintPtr>();
    final error = calloc<OpusError>();

    try {
      final inputPtr = calloc<Uint8>(input.length);
      inputPtr.asTypedList(input.length).setAll(0, input);

      final res = bindings.decode_float(
        _decoder!,
        inputPtr,
        input.length,
        output,
        maxSamples,
        fec,
        decodedSize,
        error,
      );

      calloc.free(inputPtr);

      if (res != 0) {
        final errorMsg = extractErrorMessage(error);
        throw OpusException(error.ref.code, errorMsg);
      }

      final size = decodedSize.value;
      final result = Float32List(size);
      final outputList = output.asTypedList(size);
      result.setAll(0, outputList);

      return result;
    } finally {
      freeError(error);
      calloc.free(output);
      calloc.free(decodedSize);
    }
  }

  /// 释放解码器资源
  void dispose() {
    if (_decoder != null) {
      bindings.free_decoder(_decoder!);
      _decoder = null;
    }
  }
}
