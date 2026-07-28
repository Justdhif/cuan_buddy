import 'package:flutter_riverpod/flutter_riverpod.dart';
import './profile_provider.dart';

final unlockedBordersProvider = FutureProvider<List<String>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final unlocked = profile['unlockedBorders'] as List<dynamic>? ?? [];
  return unlocked.map((e) => e.toString()).toList();
});

final achievementCheckProvider = StateNotifierProvider<AchievementCheckNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return AchievementCheckNotifier(ref);
});

class AchievementCheckNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  AchievementCheckNotifier(this.ref) : super(const AsyncData({}));

  final Ref ref;

  Future<Map<String, dynamic>> checkAndRefresh() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.checkAchievements();

      final List<dynamic> newlyUnlocked = result['newlyUnlocked'] ?? [];
      if (newlyUnlocked.isNotEmpty) {
        ref.invalidate(unlockedBordersProvider);
      }

      state = AsyncData(result);
      return result;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
