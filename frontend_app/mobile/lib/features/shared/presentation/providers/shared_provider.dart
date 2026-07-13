import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/core_providers.dart';

class SharedState {
  final List<dynamic> friends;
  final List<dynamic> pendingRequests;
  final List<dynamic> rooms;
  final Map<String, dynamic>? activeRoom;
  final List<dynamic> roomTransactions;
  final List<dynamic> roomBudgets;
  final List<dynamic> roomSavings;
  final List<dynamic> searchResults;
  final bool isLoading;
  final bool isRoomLoading;
  final String? error;

  SharedState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.rooms = const [],
    this.activeRoom,
    this.roomTransactions = const [],
    this.roomBudgets = const [],
    this.roomSavings = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isRoomLoading = false,
    this.error,
  });

  SharedState copyWith({
    List<dynamic>? friends,
    List<dynamic>? pendingRequests,
    List<dynamic>? rooms,
    Map<String, dynamic>? activeRoom,
    bool clearActiveRoom = false,
    List<dynamic>? roomTransactions,
    List<dynamic>? roomBudgets,
    List<dynamic>? roomSavings,
    List<dynamic>? searchResults,
    bool? isLoading,
    bool? isRoomLoading,
    String? error,
    bool clearError = false,
  }) {
    return SharedState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      rooms: rooms ?? this.rooms,
      activeRoom: clearActiveRoom ? null : (activeRoom ?? this.activeRoom),
      roomTransactions: roomTransactions ?? this.roomTransactions,
      roomBudgets: roomBudgets ?? this.roomBudgets,
      roomSavings: roomSavings ?? this.roomSavings,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isRoomLoading: isRoomLoading ?? this.isRoomLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SharedNotifier extends StateNotifier<SharedState> {
  SharedNotifier(this.ref) : super(SharedState()) {
    fetchLobbyData();
  }

  final Ref ref;

  DioClient get _dioClient => ref.read(dioClientProvider);

  Future<void> fetchLobbyData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        fetchFriends(silent: true),
        fetchPendingRequests(silent: true),
        fetchRooms(silent: true),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchFriends({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dioClient.dio.get('/friendships');
      if (res.statusCode == 200) {
        state = state.copyWith(friends: res.data as List);
      }
    } catch (e) {
      if (!silent) state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> fetchPendingRequests({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dioClient.dio.get('/friendships/pending');
      if (res.statusCode == 200) {
        state = state.copyWith(pendingRequests: res.data as List);
      }
    } catch (e) {
      if (!silent) state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> fetchRooms({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dioClient.dio.get('/rooms');
      if (res.statusCode == 200) {
        state = state.copyWith(rooms: res.data as List);
      }
    } catch (e) {
      if (!silent) state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dioClient.dio.get('/friendships/search', queryParameters: {'query': query});
      if (res.statusCode == 200) {
        state = state.copyWith(searchResults: res.data as List, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> sendFriendRequest(String usernameOrEmail) async {
    try {
      final res = await _dioClient.dio.post('/friendships/request', data: {
        'usernameOrEmail': usernameOrEmail,
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchPendingRequests(silent: true);
        return null; // Success
      }
      return res.data['message'] ?? 'Failed to send friend request';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> respondFriendRequest(String friendshipId, String action) async {
    try {
      final res = await _dioClient.dio.post('/friendships/respond', data: {
        'friendshipId': friendshipId,
        'action': action,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchLobbyData();
        return null; // Success
      }
      return res.data['message'] ?? 'Failed to respond to request';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createRoom(
    String name,
    List<String> memberUserIds, {
    String emojiIcon = '📁',
    String colorCode = '#6C63FF',
    String? description,
  }) async {
    try {
      final res = await _dioClient.dio.post('/rooms', data: {
        'name': name,
        'memberUserIds': memberUserIds,
        'emojiIcon': emojiIcon,
        'colorCode': colorCode,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      });
      if (res.statusCode == 201) {
        await fetchRooms(silent: true);
        return null; // Success
      }
      return res.data['message'] ?? 'Failed to create room';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> fetchRoomDetails(String roomId) async {
    state = state.copyWith(isRoomLoading: true, error: null);
    try {
      final roomRes = await _dioClient.dio.get('/rooms/$roomId');
      final txRes = await _dioClient.dio.get('/transactions', queryParameters: {'roomId': roomId, 'limit': 100});
      final budgetRes = await _dioClient.dio.get('/budgets', queryParameters: {'roomId': roomId, 'limit': 100});
      final savingsRes = await _dioClient.dio.get('/goals', queryParameters: {'roomId': roomId, 'limit': 100});

      List txList = [];
      if (txRes.data is List) {
        txList = txRes.data;
      } else if (txRes.data is Map && txRes.data['data'] is List) {
        txList = txRes.data['data'];
      }

      List budgetList = [];
      if (budgetRes.data is List) {
        budgetList = budgetRes.data;
      } else if (budgetRes.data is Map && budgetRes.data['data'] is List) {
        budgetList = budgetRes.data['data'];
      }

      List savingsList = [];
      if (savingsRes.data is List) {
        savingsList = savingsRes.data;
      } else if (savingsRes.data is Map && savingsRes.data['data'] is List) {
        savingsList = savingsRes.data['data'];
      }

      state = state.copyWith(
        activeRoom: roomRes.data as Map<String, dynamic>,
        roomTransactions: txList,
        roomBudgets: budgetList,
        roomSavings: savingsList,
        isRoomLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isRoomLoading: false, error: e.toString());
    }
  }

  Future<String?> leaveOrDeleteRoom(String roomId) async {
    try {
      final res = await _dioClient.dio.delete('/rooms/$roomId');
      if (res.statusCode == 200) {
        state = state.copyWith(clearActiveRoom: true);
        await fetchRooms(silent: true);
        return null;
      }
      return res.data['message'] ?? 'Failed to delete or leave room';
    } catch (e) {
      return e.toString();
    }
  }

  void clearActiveRoom() {
    state = state.copyWith(clearActiveRoom: true, roomTransactions: [], roomBudgets: [], roomSavings: []);
  }

  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }
}

final sharedNotifierProvider = StateNotifierProvider<SharedNotifier, SharedState>((ref) {
  return SharedNotifier(ref);
});
