import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/models/request_models/login_request_model.dart';
import 'package:mobile/service/sin_in_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingInCubit extends Cubit<SingInState> {
  BuildContext context;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  bool isLoading = false;

  SingInCubit(
      this.context, this.formKey, this.emailController, this.passwordController)
      : super(SingInInitialState());

  Future<void> login() async {
    changeLoadingView();
    if (formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      await SignInService.login(
              LoginRequestModel(email: "test@test.com", password: "password"))
          .then((response) async {
        if (!response.error) {
          await SharedPreferences.getInstance().then((prefs) {
            prefs.setString('id', response.userId.toString());
            prefs.setString('token', response.token.toString());
            prefs.setString('email', email);
            prefs.setString('password', password);

            emit(SingInLoginState(true, true));
          });
        } else {
          emit(SingInLoginState(false, null));
        }
      });
      return;
    }
    changeLoadingView();
  }

  void changeLoadingView() {
    isLoading = !isLoading;
    emit(SingInLoadingState(isLoading));
  }
}

abstract class SingInState {}

class SingInInitialState extends SingInState {}

class SingInLoadingState extends SingInState {
  final bool isLoading;

  SingInLoadingState(this.isLoading);
}

class SingInLoginState extends SingInState {
  final bool isSuccess;
  final bool? isHaveFeatures;

  SingInLoginState(this.isSuccess, this.isHaveFeatures);
}
