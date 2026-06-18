import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(dioClient: ref.watch(dioClientProvider));
});

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(profileRepositoryProvider).getProfile();
});

// ─── Backup Settings Provider ─────────────────────────────────────────────────
final backupSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(profileRepositoryProvider).getBackupSettings();
});
