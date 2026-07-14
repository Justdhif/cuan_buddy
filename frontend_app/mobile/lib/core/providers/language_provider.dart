import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';
import 'core_providers.dart';

/// Manages the persisted language preference (stores a BCP-47 language code).
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier(this._prefs, this._ref) : super(_prefs.languageCode);

  final PreferencesService _prefs;
  final Ref _ref;

  /// Switch to a new language code, e.g. 'en' or 'id'.
  Future<void> setLanguage(String code) async {
    await _prefs.setLanguageCode(code);
    state = code;

    // Sync language selection to backend
    try {
      final dio = _ref.read(dioClientProvider).dio;
      await dio.patch('/profiles/me', data: {'language': code});
    } catch (_) {
      // Ignore network errors on language change
    }
  }
}

/// Provides the current language code ('en' or 'id').
/// Persisted to SharedPreferences across app restarts.
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return LanguageNotifier(prefs, ref);
});
