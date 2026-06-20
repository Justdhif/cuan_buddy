import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/core_providers.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  
  ChatMessage({required this.role, required this.content});
}

class AiState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AiState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  AiNotifier(this.ref) : super(AiState(messages: [
    ChatMessage(
      role: 'assistant', 
      content: 'Hi! I am CuanBuddy AI. You can ask me anything about your finances, budget recommendations, or spending habits.',
    )
  ]));

  final Ref ref;

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.post('/ai/chat', data: {'message': text});
      
      final replyText = response.data['reply'] as String? ?? 'Sorry, I could not process that.';
      final aiMsg = ChatMessage(role: 'assistant', content: replyText);
      
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        messages: [
          ...state.messages,
          ChatMessage(role: 'assistant', content: 'Oops! I am having trouble connecting to the server.')
        ]
      );
    }
  }

  Future<Map<String, dynamic>?> processVoiceTransaction(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      final response = await dio.post('/ai/voice-transaction', data: formData);
      state = state.copyWith(isLoading: false);
      
      // Return the parsed data
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
  return response.data['insights'] as String? ?? 'No insights available right now.';
});

final aiBudgetRecommendationProvider = FutureProvider<String>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/ai/budget-recommendation');
  return response.data['recommendation'] as String? ?? 'No recommendations available.';
});
