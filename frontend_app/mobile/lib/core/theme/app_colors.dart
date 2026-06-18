import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand Colors ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFA78BFA);
  static const Color primaryLight = Color(0xFFC4B5FD);
  static const Color primaryDark = Color(0xFF7C3AED);

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
  static const Color backgroundLight = Color(0xFFFAFAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textHintLight = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // ─── Dark Mode ───────────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textHintDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
  );

  static const LinearGradient balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA), Color(0xFF6EE7B7)],
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
    Color(0xFFA78BFA),
    Color(0xFF6EE7B7),
    Color(0xFFFDBA74),
    Color(0xFFFB7185),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFCD34D),
  ];
}
