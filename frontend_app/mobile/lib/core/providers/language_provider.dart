import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';
import 'core_providers.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier(this._prefs, this._ref) : super(_prefs.languageCode);

  final PreferencesService _prefs;
  final Ref _ref;

  Future<void> setLanguage(String code) async {
    await _prefs.setLanguageCode(code);
    state = code;

    try {
      final dio = _ref.read(dioClientProvider).dio;
      await dio.patch('/profiles/me', data: {'language': code});
    } catch (_) {

    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return LanguageNotifier(prefs, ref);
});
