import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

enum BottomNavBehavior {
  alwaysVisible,
  autoShowOnPause,
  manualChevron;

  String toStorageString() {
    switch (this) {
      case BottomNavBehavior.alwaysVisible:
        return 'alwaysVisible';
      case BottomNavBehavior.autoShowOnPause:
        return 'autoShowOnPause';
      case BottomNavBehavior.manualChevron:
        return 'manualChevron';
    }
  }

  static BottomNavBehavior fromString(String? value) {
    switch (value) {
      case 'alwaysVisible':
        return BottomNavBehavior.alwaysVisible;
      case 'manualChevron':
        return BottomNavBehavior.manualChevron;
      case 'autoShowOnPause':
      default:
        return BottomNavBehavior.autoShowOnPause;
    }
  }

  String getDisplayName({required bool isIndonesian}) {
    switch (this) {
      case BottomNavBehavior.alwaysVisible:
        return isIndonesian ? 'Selalu Tampil' : 'Always Visible';
      case BottomNavBehavior.autoShowOnPause:
        return isIndonesian
            ? 'Otomatis Saat Pause'
            : 'Auto Show on Pause';
      case BottomNavBehavior.manualChevron:
        return isIndonesian
            ? 'Manual Chevron'
            : 'Manual Chevron';
    }
  }

  String getDescription({required bool isIndonesian}) {
    switch (this) {
      case BottomNavBehavior.alwaysVisible:
        return isIndonesian
            ? 'Bottom bar tetap terlihat di posisi paling bawah layar.'
            : 'Bottom bar stays fixed at the bottom of the screen.';
      case BottomNavBehavior.autoShowOnPause:
        return isIndonesian
            ? 'Bottom bar hilang saat scroll, dan otomatis muncul kembali saat Anda berhenti scroll atau mentok di ujung.'
            : 'Bottom bar hides while scrolling and appears automatically when you pause or reach the end.';
      case BottomNavBehavior.manualChevron:
        return isIndonesian
            ? 'Bottom bar hilang saat scroll. Tombol chevron digunakan untuk buka/tutup (otomatis muncul saat mentok atas/bawah).'
            : 'Bottom bar hides while scrolling. Chevron button toggles it (auto-shows at top/bottom).';
    }
  }
}

class BottomNavBehaviorNotifier extends Notifier<BottomNavBehavior> {
  @override
  BottomNavBehavior build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return BottomNavBehavior.fromString(prefs.bottomNavBehavior);
  }

  Future<void> setBehavior(BottomNavBehavior behavior) async {
    state = behavior;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setBottomNavBehavior(behavior.toStorageString());
  }
}

final bottomNavBehaviorProvider =
    NotifierProvider<BottomNavBehaviorNotifier, BottomNavBehavior>(
  BottomNavBehaviorNotifier.new,
);
