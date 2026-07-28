import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'PlusJakartaSans';

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),

        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),

        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),

        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),

        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      );
}

