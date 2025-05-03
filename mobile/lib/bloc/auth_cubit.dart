import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/models/request_models/login_request_model.dart';
import 'package:mobile/service/sin_in_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String email;

  const AuthAuthenticated(this.email);

  @override
  List<Object> get props => [email];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  // Başlangıçta token kontrolü yap
  Future<void> checkAuthState() async {
    emit(AuthLoading());

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final email = prefs.getString('email');

    if (token != null && email != null) {
      emit(AuthAuthenticated(email));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // Giriş yap
  Future<bool> login(String email, String password) async {
    emit(AuthLoading());

    try {
      final response = await SignInService.login(LoginRequestModel(email: email, password: password));

      if (!response.error) {
        // Kullanıcı bilgilerini kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.token ?? "");
        await prefs.setString('id', response.userId.toString());
        await prefs.setString('email', email);

        emit(AuthAuthenticated(email));
        return true;
      } else {
        emit(AuthError(response.message));
        return false;
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    emit(AuthLoading());

    try {
      // Yerel depolamadan kullanıcı bilgilerini temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('id');
      await prefs.remove('email');

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}