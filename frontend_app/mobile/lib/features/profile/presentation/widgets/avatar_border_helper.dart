/// Shared config & utilities untuk sistem avatar border.
///
/// Untuk menambah border baru:
///   1. Taruh file PNG di `assets/borders/`
///   2. Tambah entry di [kAvailableBorders]
library;

const String kBorderPrefKey = 'selected_avatar_border';

/// Daftar semua border yang tersedia di aplikasi.
const List<Map<String, String>> kAvailableBorders = [
  {'id': 'none',     'label': 'None',     'asset': ''},
  {'id': 'border-1', 'label': 'Border 1', 'asset': 'assets/borders/border-1.png'},
  {'id': 'border-2', 'label': 'Border 2', 'asset': 'assets/borders/border-2.png'},
];

/// Mengembalikan asset path dari border ID.
/// Jika ID tidak ditemukan, mengembalikan string kosong (no border).
String borderAssetFromId(String? id) {
  if (id == null) return '';
  return kAvailableBorders
      .firstWhere(
        (b) => b['id'] == id,
        orElse: () => kAvailableBorders.first,
      )['asset']!;
}
