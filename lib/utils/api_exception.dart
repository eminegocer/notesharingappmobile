class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status Code: $statusCode)';
    }
    return 'ApiException: $message';
  }

  // Yaygın API hataları için factory metodlar
  factory ApiException.unauthorized() {
    return ApiException(
      message: 'Unauthorized access. Please login again.',
      statusCode: 401,
    );
  }

  factory ApiException.networkError() {
    return ApiException(
      message: 'Network connection error. Please check your internet connection.',
    );
  }

  factory ApiException.serverError() {
    return ApiException(
      message: 'Server error occurred. Please try again later.',
      statusCode: 500,
    );
  }

  factory ApiException.notFound() {
    return ApiException(
      message: 'Requested resource not found.',
      statusCode: 404,
    );
  }

  factory ApiException.badRequest(String? details) {
    return ApiException(
      message: 'Bad request: ${details ?? "Invalid data provided"}',
      statusCode: 400,
    );
  }

  factory ApiException.forbidden() {
    return ApiException(
      message: 'Access forbidden. You do not have permission to access this resource.',
      statusCode: 403,
    );
  }

  factory ApiException.timeout() {
    return ApiException(
      message: 'Request timeout. Please try again.',
      statusCode: 408,
    );
  }

  factory ApiException.conflict() {
    return ApiException(
      message: 'Conflict occurred. The resource might have been modified.',
      statusCode: 409,
    );
  }

  factory ApiException.tooManyRequests() {
    return ApiException(
      message: 'Too many requests. Please try again later.',
      statusCode: 429,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
} 