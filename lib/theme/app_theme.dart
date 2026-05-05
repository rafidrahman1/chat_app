import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand color mapping:
  // primary = black, secondary = red accent.
  static const Color primaryBlack = Colors.black;
  static const Color secondaryRed = Colors.redAccent;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryBlack,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlack,
      secondary: secondaryRed,
      surface: primaryBlack,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      tertiary: Colors.grey,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlack,
      foregroundColor: Colors.white,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: primaryBlack),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryBlack,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: secondaryRed, width: 3),
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );
}
