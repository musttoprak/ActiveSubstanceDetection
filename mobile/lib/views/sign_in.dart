import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/sign_in_bloc.dart';
import 'package:mobile/views/home.dart';

import '../components/show_snackbar.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SignInMixin {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SingInCubit(context, _formKey, _emailController, _passwordController),
      child: BlocConsumer<SingInCubit, SingInState>(
        listener: (context, state) {
          // BlocConsumer'ın listener kısmı, sadece durum değiştiğinde bir kez çalışacak
          if (state is SingInLoginState) {
            if (state.isSuccess) {
              ShowMySnackbar.snackbarShow(
                  context, true, "Giriş işlemi başarılıyla gerçekleştirildi");

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const HomePageScreen();
                  },
                ),
                    (route) => false,
              );
            } else {
              ShowMySnackbar.snackbarShow(
                  context,
                  false,
                  state.errorMessage ?? "Lütfen giriş bilgilerinizi kontrol ediniz."
              );
            }
          }
        },
        builder: (context, state) {
          // Builder kısmı UI'ı oluşturmak için kullanılacak
          return buildScaffold(context, state);
        },
      ),
    );
  }
}

mixin SignInMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Scaffold buildScaffold(BuildContext context, SingInState state) {
    final size = MediaQuery.of(context).size;
    final isLoading = state is SingInLoadingState;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF0F7FF)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.08),
                        Center(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C9EFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C9EFF).withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF6C9EFF),
                              size: 35,
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.05),
                        Center(
                          child: Text(
                            "Tekrar Hoşgeldiniz",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            "Devam etmek için oturum açın",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.06),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Email",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  enabled: !isLoading,
                                  decoration: InputDecoration(
                                    hintText: 'kullanıcı@ornek.com',
                                    hintStyle: TextStyle(color: Colors.black38),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF6C9EFF),
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF6C9EFF),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.redAccent.withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Lütfen e-posta adresinizi girin';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Şifre",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StatefulBuilder(
                                  builder: (context, setState) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _passwordController,
                                        enabled: !isLoading,
                                        obscureText: !_isPasswordVisible,
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          hintStyle: TextStyle(color: Colors.black38),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline_rounded,
                                            color: Color(0xFF6C9EFF),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_rounded
                                                  : Icons.visibility_off_rounded,
                                              color: Colors.black45,
                                            ),
                                            onPressed: !isLoading ? () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            } : null,
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFF6C9EFF),
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.redAccent.withOpacity(0.5),
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lütfen şifrenizi girin';
                                          }
                                          return null;
                                        },
                                      ),
                                    );
                                  }
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: !isLoading ? () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<SingInCubit>().login();
                                  }
                                } : null,
                                onLongPress: !isLoading ? () {
                                  context.read<SingInCubit>().loginTest();
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  elevation: 1,
                                  shadowColor: Color(0xFF6C9EFF).withOpacity(0.5),
                                  backgroundColor: const Color(0xFF6C9EFF),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFF6C9EFF).withOpacity(0.6),
                                  disabledForegroundColor: Colors.white.withOpacity(0.8),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  "Giriş Yap",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}