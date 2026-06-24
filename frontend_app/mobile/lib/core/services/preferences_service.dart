import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // ─── Theme ────────────────────────────────────────────────────────────────────
  ThemeMode get themeMode {
    final value = _prefs.getString(AppConstants.themeModeKey);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(AppConstants.themeModeKey, value);
  }

  // ─── Currency ────────────────────────────────────────────────────────────────
  String get currencyCode =>
      _prefs.getString(AppConstants.currencyCodeKey) ??
      AppConstants.defaultCurrency;

  Future<void> setCurrencyCode(String code) async {
    await _prefs.setString(AppConstants.currencyCodeKey, code);
  }

  // ─── Language ─────────────────────────────────────────────────────────────────
  String get languageCode =>
      _prefs.getString(AppConstants.languageKey) ??
      AppConstants.defaultLanguage;

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(AppConstants.languageKey, code);
  }

  // ─── Notifications ───────────────────────────────────────────────────────────
  bool get notificationsEnabled =>
      _prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.notificationsEnabledKey, enabled);
  }

  // ─── Onboarding Flags ────────────────────────────────────────────────────────
  bool get profileComplete =>
      _prefs.getBool(AppConstants.profileCompleteKey) ?? false;

  Future<void> setProfileComplete(bool complete) async {
    await _prefs.setBool(AppConstants.profileCompleteKey, complete);
  }

  bool get backupSetupComplete =>
      _prefs.getBool(AppConstants.backupSetupCompleteKey) ?? false;

  Future<void> setBackupSetupComplete(bool complete) async {
    await _prefs.setBool(AppConstants.backupSetupCompleteKey, complete);
  }

  bool get onboardingComplete =>
      _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(AppConstants.onboardingCompleteKey, complete);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
