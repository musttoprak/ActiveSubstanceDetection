class LoginResponseModel {
  final String? token;
  final String? userId;
  final bool error;
  final String message;

  LoginResponseModel({this.token, this.userId,required this.error, required this.message});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'].toString(),
      userId: json['userId'].toString(),
      error: json['error'] ?? "Unknown error",
      message: json['message'] ?? "Unknown error",
    );
  }
}