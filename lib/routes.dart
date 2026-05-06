import 'package:flutter/material.dart';
import 'pages/home_screen.dart';
import 'pages/login_screen.dart';
import 'pages/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {login: (context) => LoginScreen(), home: (context) => HomeScreen(), settings: (context) => const SettingsScreen()};
}
