import 'package:closet_ai/core/services/api_client.dart';

class ChatRepository {
  ChatRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createConversation({
    String title = 'New chat',
  }) async {
    return _apiClient.post('/chat/conversations', data: {'title': title});
  }

  Future<Map<String, dynamic>> listConversations({
    int page = 1,
    int limit = 20,
  }) async {
    return _apiClient.getWithQuery(
      '/chat/conversations',
      query: {'page': page, 'limit': limit},
    );
  }

  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    return _apiClient.get('/chat/conversations/$conversationId');
  }

  Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    return _apiClient.delete('/chat/conversations/$conversationId');
  }

  Future<Map<String, dynamic>> listMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  }) async {
    return _apiClient.getWithQuery(
      '/chat/conversations/$conversationId/messages',
      query: {'page': page, 'limit': limit},
    );
  }

  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String message,
  ) async {
    return _apiClient.post(
      '/chat/conversations/$conversationId/messages',
      data: {'message': message},
    );
  }

  Future<Map<String, dynamic>> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    return _apiClient.delete(
      '/chat/conversations/$conversationId/messages/$messageId',
    );
  }
}
