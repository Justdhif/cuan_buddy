import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/preferences_service.dart';
import 'core_providers.dart';

/// A notifier that tracks and persists ThemeMode changes.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_prefs.themeMode);

  final PreferencesService _prefs;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(mode);
    state = mode;
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier(this._prefs) : super(_prefs.accentColor) {
    AppColors.primary = state;
  }

  final PreferencesService _prefs;

  Future<void> setAccentColor(Color color) async {
    await _prefs.setAccentColor(color);
    state = color;
    AppColors.primary = color;
  }

  Future<void> resetAccentColor() async {
    await setAccentColor(AppColors.defaultPrimary);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ThemeModeNotifier(prefs);
});

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return AccentColorNotifier(prefs);
});
