import 'dart:async';

import 'package:closet_ai/core/services/api_client.dart';
import 'package:closet_ai/features/ai_stylist/data/chat_repository.dart';
import 'package:closet_ai/features/ai_stylist/domain/chat_models.dart';
import 'package:closet_ai/features/subscription/providers/subscription_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(apiClient: ref.read(apiClientProvider)),
);

class ChatState {
  const ChatState({
    this.conversationId,
    this.conversations = const [],
    this.messages = const [],
    this.isInitializing = true,
    this.isSending = false,
    this.isTyping = false,
    this.errorMessage,
    this.isPremiumRequired = false,
  });

  final String? conversationId;
  final List<ChatConversationSummary> conversations;
  final List<ChatMessageModel> messages;
  final bool isInitializing;
  final bool isSending;
  final bool isTyping;
  final String? errorMessage;
  final bool isPremiumRequired;

  ChatState copyWith({
    String? conversationId,
    bool clearConversationId = false,
    List<ChatConversationSummary>? conversations,
    List<ChatMessageModel>? messages,
    bool? isInitializing,
    bool? isSending,
    bool? isTyping,
    String? errorMessage,
    bool clearError = false,
    bool? isPremiumRequired,
  }) {
    return ChatState(
      conversationId: clearConversationId
          ? null
          : (conversationId ?? this.conversationId),
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isInitializing: isInitializing ?? this.isInitializing,
      isSending: isSending ?? this.isSending,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPremiumRequired: isPremiumRequired ?? this.isPremiumRequired,
    );
  }
}

bool _isPremiumRequiredError(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final details = data['details'];
    if (details is Map && details['code'] == 'PREMIUM_REQUIRED') return true;
  }
  return error.response?.statusCode == 403;
}

const String _premiumRequiredMessage =
    'You have used all your free AI Stylist chats this month. Upgrade to Premium for unlimited access.';

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repository) : super(const ChatState()) {
    unawaited(_bootstrap());
  }

  final ChatRepository _repository;

  Future<void> _bootstrap() async {
    await loadConversations();
    await startNewChat();
  }

  Future<void> loadConversations() async {
    try {
      final response = await _repository.listConversations();
      final data = response['data'];
      if (data is List) {
        state = state.copyWith(
          conversations: data
              .whereType<Map>()
              .map(
                (item) => ChatConversationSummary.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      }
    } on DioException catch (error) {
      state = state.copyWith(
        errorMessage: ApiClient.extractErrorMessage(error),
      );
    }
  }

  Future<void> startNewChat() async {
    state = state.copyWith(
      isInitializing: true,
      clearError: true,
      clearConversationId: true,
      messages: const [],
      isPremiumRequired: false,
    );
    try {
      final response = await _repository.createConversation(
        title: 'New stylist chat',
      );
      final data = response['data'];
      final id = (data is Map ? data['_id'] : null)?.toString();
      if (id == null || id.isEmpty) {
        throw const FormatException('Missing conversation id in response');
      }
      state = state.copyWith(conversationId: id);
      await _loadMessages();
      await loadConversations();
      state = state.copyWith(isInitializing: false);
    } on DioException catch (error) {
      final premiumRequired = _isPremiumRequiredError(error);
      state = state.copyWith(
        isInitializing: false,
        isPremiumRequired: premiumRequired,
        errorMessage: premiumRequired
            ? _premiumRequiredMessage
            : ApiClient.extractErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: 'Unable to start a chat right now. Please try again.',
      );
    }
  }

  Future<void> openConversation(String conversationId) async {
    if (conversationId == state.conversationId) return;
    state = state.copyWith(
      conversationId: conversationId,
      messages: const [],
      clearError: true,
      isInitializing: true,
    );
    await _loadMessages();
    state = state.copyWith(isInitializing: false);
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _repository.deleteConversation(conversationId);
      state = state.copyWith(
        conversations: state.conversations
            .where((conversation) => conversation.id != conversationId)
            .toList(),
      );
      if (state.conversationId == conversationId) {
        await startNewChat();
      }
    } on DioException catch (error) {
      state = state.copyWith(
        errorMessage: ApiClient.extractErrorMessage(error),
      );
    }
  }

  Future<void> _loadMessages() async {
    final conversationId = state.conversationId;
    if (conversationId == null) return;
    try {
      final response = await _repository.listMessages(conversationId);
      final data = response['data'];
      if (data is List) {
        state = state.copyWith(
          messages: data
              .whereType<Map>()
              .map(
                (item) =>
                    ChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
      }
    } on DioException catch (error) {
      state = state.copyWith(
        errorMessage: ApiClient.extractErrorMessage(error),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    final conversationId = state.conversationId;
    if (trimmed.isEmpty || conversationId == null || state.isSending) return;

    final optimisticMessage = ChatMessageModel(
      id: '_optimistic_${state.messages.length}',
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      isSending: true,
      isTyping: true,
      clearError: true,
      messages: [...state.messages, optimisticMessage],
    );

    try {
      await _repository.sendMessage(conversationId, trimmed);
      await _loadMessages();
      await loadConversations();
    } on DioException catch (error) {
      final premiumRequired = _isPremiumRequiredError(error);
      state = state.copyWith(
        isPremiumRequired: premiumRequired,
        errorMessage: premiumRequired
            ? _premiumRequiredMessage
            : ApiClient.extractErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'The stylist could not respond. Please try again.',
      );
    } finally {
      state = state.copyWith(isSending: false, isTyping: false);
    }
  }

  Future<void> retry() async {
    if (state.conversationId == null) {
      await startNewChat();
      return;
    }
    state = state.copyWith(clearError: true);
    await _loadMessages();
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((
  ref,
) {
  return ChatController(ref.read(chatRepositoryProvider));
});
