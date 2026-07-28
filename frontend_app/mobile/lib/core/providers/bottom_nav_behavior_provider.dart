import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

enum BottomNavBehavior {
  alwaysVisible,
  autoShowOnPause;

  String toStorageString() {
    switch (this) {
      case BottomNavBehavior.alwaysVisible:
        return 'alwaysVisible';
      case BottomNavBehavior.autoShowOnPause:
        return 'autoShowOnPause';
    }
  }

  static BottomNavBehavior fromString(String? value) {
    switch (value) {
      case 'alwaysVisible':
        return BottomNavBehavior.alwaysVisible;
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
            ? 'Sembunyikan Saat Scroll'
            : 'Hide on Scroll';
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
            ? 'Bottom bar otomatis sembunyi saat Anda scroll dan muncul kembali saat berhenti.'
            : 'Bottom bar automatically hides when you scroll and reappears when you stop.';
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
