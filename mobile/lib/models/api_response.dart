class ApiResponse<T> {
  final bool error;
  final String message;
  final T? data;

  ApiResponse({
    required this.error,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) create) {
    return ApiResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? create(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'data': data,
    };
  }
}
