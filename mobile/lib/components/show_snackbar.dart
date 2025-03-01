import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ShowMySnackbar {
  static void snackbarShow(BuildContext context, bool isSuccess, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        showCloseIcon: false,
        content: Row(
          children: [
            SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                    isSuccess ? "assets/success.json" : "assets/fail.json")),
            const SizedBox(width: 24),
            Text(text),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}