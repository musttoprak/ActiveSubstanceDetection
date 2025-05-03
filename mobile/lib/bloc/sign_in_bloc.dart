import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/models/request_models/login_request_model.dart';
import 'package:mobile/service/sin_in_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// States
abstract class SingInState {}

class SingInInitialState extends SingInState {}

class SingInLoadingState extends SingInState {}

class SingInLoginState extends SingInState {
  final bool isSuccess;
  final String? errorMessage;

  SingInLoginState(this.isSuccess, this.errorMessage);
}

// Cubit
class SingInCubit extends Cubit<SingInState> {
  final BuildContext context;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  SingInCubit(this.context, this.formKey, this.emailController, this.passwordController)
      : super(SingInInitialState());

  void changeLoadingView() {
    if (state is SingInLoadingState) {
      emit(SingInInitialState());
    } else {
      emit(SingInLoadingState());
    }
  }

  Future<void> login() async {
    emit(SingInLoadingState());

    if (formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      try {
        final response = await SignInService.login(
            LoginRequestModel(email: email, password: password));

        if (!response.error) {
          await SharedPreferences.getInstance().then((prefs) {
            prefs.setString('id', response.userId.toString());
            prefs.setString('token', response.token.toString());
            prefs.setString('email', email);
            prefs.setString('password', password);

            emit(SingInLoginState(true, null));
          });
        } else {
          // API'den gelen hata mesajını kullan
          emit(SingInLoginState(false, response.message));
        }
      } catch (e) {
        // Beklenmeyen hata durumunda genel bir mesaj
        emit(SingInLoginState(false, "Giriş sırasında bir hata oluştu. Lütfen tekrar deneyin."));
      }
    } else {
      emit(SingInInitialState());
    }
  }

  Future<void> loginTest() async {
    emit(SingInLoadingState());

    // Test giriş bilgileri - geliştirme aşamasında kullanılması için
    String email = "test@test.com";
    String password = "password";

    try {
      final response = await SignInService.login(
          LoginRequestModel(email: email, password: password));

      if (!response.error) {
        await SharedPreferences.getInstance().then((prefs) {
          prefs.setString('id', response.userId.toString());
          prefs.setString('token', response.token.toString());
          prefs.setString('email', email);
          prefs.setString('password', password);

          emit(SingInLoginState(true, null));
        });
      } else {
        emit(SingInLoginState(false, response.message));
      }
    } catch (e) {
      emit(SingInLoginState(false, "Giriş sırasında bir hata oluştu. Lütfen tekrar deneyin."));
    }
  }
}