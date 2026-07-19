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
final backupSettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(profileRepositoryProvider).getBackupSettings();
});

// ─── Backup File Model ─────────────────────────────────────────────────────────
final avatarBordersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getAvatarBorders();
});

final bannerBordersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getBannerBorders();
});

class BackupFile {
  const BackupFile({
    required this.id,
    required this.label,
    required this.filename,
    required this.createdAt,
    this.isDownloading = false,
    this.isDeleting = false,
  });

  final String id;
  final String label;
  final String filename;
  final DateTime createdAt;
  final bool isDownloading;
  final bool isDeleting;

  BackupFile copyWith({
    bool? isDownloading,
    bool? isDeleting,
  }) {
    return BackupFile(
      id: id,
      label: label,
      filename: filename,
      createdAt: createdAt,
      isDownloading: isDownloading ?? this.isDownloading,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

// ─── Backup Files Notifier ─────────────────────────────────────────────────────
class BackupFilesNotifier extends Notifier<List<BackupFile>> {
  static const _storageKey = 'backup_files_list';

  @override
  List<BackupFile> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final listJson = prefs.getStringList(_storageKey);
    if (listJson == null) {
      final initial = _mockBackupFiles();
      _saveToPrefs(initial);
      return initial;
    }
    try {
      return listJson.map((item) {
        final parts = item.split('|');
        return BackupFile(
          id: parts[0],
          label: parts[1],
          filename: parts[2],
          createdAt: DateTime.parse(parts[3]),
        );
      }).toList();
    } catch (_) {
      final initial = _mockBackupFiles();
      _saveToPrefs(initial);
      return initial;
    }
  }

  void _saveToPrefs(List<BackupFile> list) {
    final prefs = ref.read(sharedPreferencesProvider);
    final listJson = list.map((f) => '${f.id}|${f.label}|${f.filename}|${f.createdAt.toIso8601String()}').toList();
    prefs.setStringList(_storageKey, listJson);
  }

  /// Seed with mock data (replace with real API call)
  List<BackupFile> _mockBackupFiles() {
    final now = DateTime.now();
    return [
      BackupFile(
        id: '1',
        label: 'justNow',
        filename: 'cuanbuddy_backup_2026-07-12_10-00-00.sql',
        createdAt: now,
      ),
      BackupFile(
        id: '2',
        label: 'hoursAgo22',
        filename: 'cuanbuddy_backup_2026-07-11_12-00-00.sql',
        createdAt: now.subtract(const Duration(hours: 22)),
      ),
      BackupFile(
        id: '3',
        label: 'daysAgo3',
        filename: 'cuanbuddy_backup_2026-07-09_10-00-00.sql',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      BackupFile(
        id: '4',
        label: 'daysAgo5',
        filename: 'cuanbuddy_backup_2026-07-07_10-00-00.sql',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      BackupFile(
        id: '5',
        label: 'jun26',
        filename: 'cuanbuddy_backup_2026-06-26_10-00-00.sql',
        createdAt: DateTime(now.year, 6, 26),
      ),
    ];
  }

  /// Add a new backup entry to the top of the list
  void addBackup(BackupFile file) {
    final newList = [file, ...state];
    state = newList;
    _saveToPrefs(newList);
  }

  /// Mark download in progress
  void setDownloading(String id, bool value) {
    state = [
      for (final f in state)
        if (f.id == id) f.copyWith(isDownloading: value) else f,
    ];
  }

  /// Remove a file entry (after deletion confirmed)
  void removeFile(String id) {
    final newList = state.where((f) => f.id != id).toList();
    state = newList;
    _saveToPrefs(newList);
  }

  /// Mark delete in progress
  void setDeleting(String id, bool value) {
    state = [
      for (final f in state)
        if (f.id == id) f.copyWith(isDeleting: value) else f,
    ];
  }

  /// Refresh from server (placeholder)
  Future<void> refresh() async {
    state = _mockBackupFiles();
    _saveToPrefs(state);
  }
}

final backupFilesProvider =
    NotifierProvider<BackupFilesNotifier, List<BackupFile>>(
  BackupFilesNotifier.new,
);

