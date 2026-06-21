import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(dioClient: ref.watch(dioClientProvider));
});

class CategoryState {
  CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  final List<dynamic> categories;
  final bool isLoading;
  final String? error;

  CategoryState copyWith({
    List<dynamic>? categories,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier(this.repository) : super(CategoryState()) {
    fetchCategories();
  }

  final CategoryRepository repository;

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await repository.getCategories();
      state = state.copyWith(categories: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> addCategory(String name, String emojiIcon, String colorCode) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.createCategory(name: name, emojiIcon: emojiIcon, colorCode: colorCode);
      await fetchCategories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.updateCategory(id: id, data: data);
      await fetchCategories();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.deleteCategory(id);
      await fetchCategories();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref.watch(categoryRepositoryProvider));
});
