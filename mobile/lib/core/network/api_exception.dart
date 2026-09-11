class ApiException implements Exception {
  const ApiException({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() {
    if (code == null) {
      return message;
    }

    return '$code: $message';
  }
}
