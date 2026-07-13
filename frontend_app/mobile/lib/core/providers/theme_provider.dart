import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/preferences_service.dart';
import 'core_providers.dart';

/// Extended theme mode enum that adds 'sunrise' (follows sun position).
enum AppThemeMode {
  system,
  light,
  dark,
  sunrise;

  /// Convert to string for persistence.
  String toStorageString() {
    switch (this) {
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.sunrise:
        return 'sunrise';
      case AppThemeMode.system:
        return 'system';
    }
  }

  /// Parse from string.
  static AppThemeMode fromString(String? value) {
    switch (value) {
      case 'dark':
        return AppThemeMode.dark;
      case 'light':
        return AppThemeMode.light;
      case 'sunrise':
        return AppThemeMode.sunrise;
      default:
        return AppThemeMode.system;
    }
  }

  /// Resolve to a Flutter ThemeMode.
  /// For 'sunrise', light mode runs from 06:00–18:00 local time.
  ThemeMode resolve() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.sunrise:
        final hour = DateTime.now().hour;
        // Light between 06:00 (inclusive) and 18:00 (exclusive)
        return (hour >= 6 && hour < 18) ? ThemeMode.light : ThemeMode.dark;
    }
  }
}

/// A notifier that tracks and persists [AppThemeMode] changes.
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_loadInitial(_prefs));

  final PreferencesService _prefs;

  static AppThemeMode _loadInitial(PreferencesService prefs) {
    return AppThemeMode.fromString(prefs.appThemeModeString);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs.setAppThemeMode(mode);
    state = mode;
  }

  void toggle() {
    final next = state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    setThemeMode(next);
  }
}

/// Resolves the currently-active [ThemeMode] from [AppThemeMode].
/// When the mode is 'sunrise', returns light/dark based on the current hour.
final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final appMode = ref.watch(themeModeProvider);
  return appMode.resolve();
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ThemeModeNotifier(prefs);
});

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

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return AccentColorNotifier(prefs);
});
