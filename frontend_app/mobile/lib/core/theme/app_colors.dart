import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand Colors ────────────────────────────────────────────────────────────
  static const Color defaultPrimary = Color(0xFF60A5FA);
  static Color primary = defaultPrimary;

  static Color get primaryLight => _lighten(primary, 0.18);
  static Color get primaryDark => _darken(primary, 0.14);

  static const Color secondary = Color(0xFF6EE7B7);
  static const Color secondaryLight = Color(0xFFA7F3D0);
  static const Color secondaryDark = Color(0xFF059669);

  static const Color accent = Color(0xFFFDBA74);
  static const Color accentLight = Color(0xFFFED7AA);
  static const Color accentDark = Color(0xFFEA580C);

  // ─── Semantic Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4ADE80);
  static const Color successLight = Color(0xFFBBF7D0);
  static const Color successDark = Color(0xFF16A34A);

  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFEF08A);
  static const Color warningDark = Color(0xFFD97706);

  static const Color danger = Color(0xFFFB7185);
  static const Color dangerLight = Color(0xFFFECDD3);
  static const Color dangerDark = Color(0xFFE11D48);

  // ─── Light Mode ──────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textHintLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // ─── Dark Mode ───────────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1A2333);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textHintDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color dividerDark = Color(0xFF1E293B);

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary],
      );

  static LinearGradient get balanceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary, secondary],
      );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ADE80), Color(0xFF6EE7B7)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB7185), Color(0xFFFDBA74)],
  );

  // ─── Chart Pastel Colors ─────────────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF60A5FA),
    Color(0xFF6EE7B7),
    Color(0xFFFDBA74),
    Color(0xFFFB7185),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFCD34D),
  ];

  // ─── Utilities ───────────────────────────────────────────────────────────────
  static Color colorFromHex(String? hexString, {Color? fallback}) {
    final defaultFallback = fallback ?? AppColors.primary;
    if (hexString == null || hexString.isEmpty) return defaultFallback;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return defaultFallback;
    }
  }

  static Color _lighten(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  static Color _darken(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }
}
