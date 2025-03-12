class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final String perPage;
  final int total;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    final List<dynamic> items = json['data'] ?? [];
    return PaginatedResponse(
      data: items.map((item) => fromJsonT(item)).toList(),
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 15,
      total: json['total'] ?? 0,
    );
  }
}

class ApiResponse<T> {
  final String status;
  final T data;
  final String message;

  ApiResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    return ApiResponse(
      status: json['status'],
      data: fromJsonT(json['data']),
      message: json['message'],
    );
  }
}