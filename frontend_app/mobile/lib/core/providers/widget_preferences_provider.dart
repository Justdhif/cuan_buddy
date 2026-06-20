import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final selectedSavingsWidgetIdProvider = StateNotifierProvider<SelectedSavingsWidgetIdNotifier, String?>((ref) {
  return SelectedSavingsWidgetIdNotifier();
});

class SelectedSavingsWidgetIdNotifier extends StateNotifier<String?> {
  SelectedSavingsWidgetIdNotifier() : super(null) {
    _loadFromPrefs();
  }

  static const _key = 'selected_savings_widget_id';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setSelectedSavingsId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, id);
    }
    state = id;
  }
}
