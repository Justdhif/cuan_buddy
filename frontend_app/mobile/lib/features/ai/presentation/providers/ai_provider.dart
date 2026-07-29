import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/core_providers.dart';

class AiConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'],
      title: json['title'] ?? 'Chat',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class ChatMessage {
  final String? id;
  final String role;
  final String content;

  ChatMessage({this.id, required this.role, required this.content});
}

class AiState {
  final List<AiConversation> conversations;
  final String? currentConversationId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isConversationsLoading;
  final String? error;
  final bool isLimitReached;

  AiState({
    this.conversations = const [],
    this.currentConversationId,
    this.messages = const [],
    this.isLoading = false,
    this.isConversationsLoading = false,
    this.error,
    this.isLimitReached = false,
  });

  AiState copyWith({
    List<AiConversation>? conversations,
    String? currentConversationId,
    bool clearCurrentConv = false,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isConversationsLoading,
    String? error,
    bool? isLimitReached,
  }) {
    return AiState(
      conversations: conversations ?? this.conversations,
      currentConversationId: clearCurrentConv
          ? null
          : (currentConversationId ?? this.currentConversationId),
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConversationsLoading:
          isConversationsLoading ?? this.isConversationsLoading,
      error: error,
      isLimitReached: isLimitReached ?? this.isLimitReached,
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  AiNotifier(this.ref)
      : super(AiState(messages: const [])) {
    fetchConversations();
  }

  final Ref ref;

  Future<void> fetchConversations() async {
    state = state.copyWith(isConversationsLoading: true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/ai/conversations');

      final listJson = response.data['conversations'] as List? ?? [];
      final conversationsList =
          listJson.map((e) => AiConversation.fromJson(e)).toList();

      final count = response.data['count'] as int? ?? conversationsList.length;

      state = state.copyWith(
        conversations: conversationsList,
        isLimitReached: count >= 10,
        isConversationsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isConversationsLoading: false);
    }
  }

  Future<void> selectConversation(String conversationId) async {
    state = state.copyWith(
      currentConversationId: conversationId,
      isLoading: true,
      error: null,
    );

    try {
      final dio = ref.read(dioClientProvider).dio;
      final response =
          await dio.get('/ai/conversations/$conversationId/messages');

      final messagesJson = response.data['messages'] as List? ?? [];
      final fetchedMessages = messagesJson
          .map((m) => ChatMessage(
                id: m['id'],
                role: m['role'],
                content: m['content'],
              ))
          .toList();

      state = state.copyWith(
        messages: fetchedMessages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  bool startNewChat() {
    if (state.conversations.length >= 10) {
      state = state.copyWith(isLimitReached: true);
      return false;
    }

    state = state.copyWith(
      clearCurrentConv: true,
      messages: const [],
      error: null,
    );
    return true;
  }

  Future<void> sendMessage(String text) async {
    // If not in a conversation and limit is reached, block
    if (state.currentConversationId == null && state.conversations.length >= 10) {
      state = state.copyWith(
        error:
            'Batas maksimal 10 percakapan tercapai. Silakan hapus salah satu percakapan untuk memulai yang baru.',
        isLimitReached: true,
      );
      return;
    }

    final userMsg = ChatMessage(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final dio = ref.read(dioClientProvider).dio;
      final payload = {
        'message': text,
        if (state.currentConversationId != null)
          'conversationId': state.currentConversationId,
      };

      final response = await dio.post('/ai/chat', data: payload);

      final replyText = response.data['reply'] as String? ??
          'Maaf, saya tidak dapat memproses tanggapan tersebut.';
      final newConvId = response.data['conversationId'] as String?;

      final aiMsg = ChatMessage(role: 'assistant', content: replyText);

      state = state.copyWith(
        currentConversationId: newConvId ?? state.currentConversationId,
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );

      // Re-fetch conversations list to update sidebar/titles
      await fetchConversations();
    } catch (e) {
      String errMessage = 'Oops! Gagal terhubung ke server.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errMessage = data['message'].toString();
        }
      }

      state = state.copyWith(
        error: errMessage,
        isLoading: false,
        messages: [
          ...state.messages,
          ChatMessage(
            role: 'assistant',
            content: '⚠️ $errMessage',
          ),
        ],
      );
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.delete('/ai/conversations/$conversationId');

      final wasCurrent = state.currentConversationId == conversationId;
      await fetchConversations();

      if (wasCurrent) {
        startNewChat();
      }
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus percakapan');
    }
  }

  Future<void> renameConversation(String conversationId, String newTitle) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/ai/conversations/$conversationId', data: {'title': newTitle});
      await fetchConversations();
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengedit nama percakapan');
    }
  }

  Future<Map<String, dynamic>?> processVoiceTransaction(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last),
      });

      final response = await dio.post('/ai/voice-transaction', data: formData);
      state = state.copyWith(isLoading: false);

      return response.data as Map<String, dynamic>;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> processReceiptTransaction(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last),
      });

      final response = await dio.post('/ai/scan-receipt', data: formData);
      state = state.copyWith(isLoading: false);

      return response.data as Map<String, dynamic>;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return null;
    }
  }
}

final aiNotifierProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(ref);
});

final aiInsightsProvider = FutureProvider<String>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/ai/insights');
  return response.data['insights'] as String? ??
      'No insights available right now.';
});

final aiBudgetRecommendationProvider = FutureProvider<String>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/ai/budget-recommendation');
  return response.data['recommendation'] as String? ??
      'No recommendations available.';
});
