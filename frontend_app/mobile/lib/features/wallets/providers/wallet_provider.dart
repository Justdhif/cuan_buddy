import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';

final walletsProvider = StateNotifierProvider<WalletsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return WalletsNotifier(dioClient);
});

class WalletsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final DioClient _dioClient;

  WalletsNotifier(this._dioClient) : super(const AsyncValue.loading()) {
    fetchWallets();
  }

  Future<void> fetchWallets() async {
    try {
      state = const AsyncValue.loading();
      final res = await _dioClient.dio.get('/wallets');
      if (res.statusCode == 200) {
        final List data = res.data;
        state = AsyncValue.data(data.cast<Map<String, dynamic>>());
      } else {
        state = AsyncValue.error('Failed to fetch wallets', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> createWallet(Map<String, dynamic> data) async {
    try {
      final res = await _dioClient.dio.post('/wallets', data: data);
      if (res.statusCode == 201) {
        await fetchWallets();
        return null; // Success
      }
      return res.data['message'] ?? 'Failed to create wallet';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateWallet(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dioClient.dio.patch('/wallets/$id', data: data);
      if (res.statusCode == 200) {
        await fetchWallets();
        return null;
      }
      return res.data['message'] ?? 'Failed to update wallet';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteWallet(String id) async {
    try {
      final res = await _dioClient.dio.delete('/wallets/$id');
      if (res.statusCode == 200) {
        await fetchWallets();
        return null;
      }
      return res.data['message'] ?? 'Failed to delete wallet';
    } catch (e) {
      return e.toString();
    }
  }
}
