/// Opus 错误异常类
class OpusException implements Exception {
  final int code;
  final String message;

  OpusException(this.code, this.message);

  @override
  String toString() => 'OpusException(code: $code, message: $message)';
}
