// lib/models/api_response.dart
class ApiResponse<T> {
  final String status;
  final T? data;
  final Map<String, dynamic>? rawData; // Ham veriyi saklamak için eklendi
  final String message;
  final bool success;

  ApiResponse({
    required this.status,
    this.data,
    this.rawData,
    required this.message,
    required this.success,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? Function(dynamic)? fromJsonT) {
    return ApiResponse(
      status: json['status'] ?? 'error',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      rawData: json, // Tüm ham veriyi sakla
      message: json['message'] ?? 'Bilinmeyen bir hata oluştu',
      success: json['status'] == 'success',
    );
  }
}