sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class PoseException extends AppException {
  const PoseException(super.message);
}

