import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'opus_ffi.dart';
import 'opus_ffi_bindings_generated.dart';

/// 提取错误消息并释放 C 字符串
String extractErrorMessage(Pointer<OpusError> error) {
  final errorRef = error.ref;
  if (errorRef.message.address == 0) {
    return 'Unknown error (code: ${errorRef.code})';
  }

  final message = errorRef.message.cast<Utf8>().toDartString();
  final messagePtr = calloc<Pointer<Char>>();
  messagePtr.value = errorRef.message;
  bindings.free_c_string(messagePtr);
  calloc.free(messagePtr);

  return message;
}

/// 释放错误结构体
void freeError(Pointer<OpusError> error) {
  final errorRef = error.ref;
  if (errorRef.message.address != 0) {
    final messagePtr = calloc<Pointer<Char>>();
    messagePtr.value = errorRef.message;
    bindings.free_c_string(messagePtr);
    calloc.free(messagePtr);
  }
  calloc.free(error);
}
