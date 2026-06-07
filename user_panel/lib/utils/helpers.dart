import 'package:flutter/material.dart';

class SnackbarHelper {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class AppLogger {
  static void debug(String message) => debugPrint('[APP] $message');
}