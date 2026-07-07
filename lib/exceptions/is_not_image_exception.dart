class IsNotImageException implements Exception {
  final dynamic message;

  IsNotImageException([this.message]);

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "Exception";
    return "Exception: $message";
  }
}
