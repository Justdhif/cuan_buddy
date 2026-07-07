import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';
import '../theme/category_icon_shape.dart';
import 'core_providers.dart';

class CategoryIconShapeNotifier extends StateNotifier<CategoryIconShape> {
  CategoryIconShapeNotifier(this._prefs) : super(_prefs.categoryIconShape);

  final PreferencesService _prefs;

  Future<void> setShape(CategoryIconShape shape) async {
    await _prefs.setCategoryIconShape(shape);
    state = shape;
  }
}

final categoryIconShapeProvider = StateNotifierProvider<
    CategoryIconShapeNotifier, CategoryIconShape>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return CategoryIconShapeNotifier(prefs);
});
