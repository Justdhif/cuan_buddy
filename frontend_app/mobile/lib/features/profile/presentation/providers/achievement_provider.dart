import 'package:flutter_riverpod/flutter_riverpod.dart';
import './profile_provider.dart';

/// Provider untuk mengambil list border yang sudah terbuka (unlocked) dari server.
final unlockedBordersProvider = FutureProvider<List<String>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final unlocked = profile['unlockedBorders'] as List<dynamic>? ?? [];
  return unlocked.map((e) => e.toString()).toList();
});

/// State notifier atau provider untuk memicu evaluasi achievement dan mendeteksi border baru.
final achievementCheckProvider = StateNotifierProvider<AchievementCheckNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return AchievementCheckNotifier(ref);
});

class AchievementCheckNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  AchievementCheckNotifier(this.ref) : super(const AsyncData({}));

  final Ref ref;

  /// Meminta server memeriksa achievement dan memperbarui list border jika ada yang baru dibuka.
  Future<Map<String, dynamic>> checkAndRefresh() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.checkAchievements();
      
      // Jika ada border baru yang berhasil terbuka, invalidate list border yang terbuka
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
