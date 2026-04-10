import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../models/chat_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(dioProvider));
});

class ChatRepository {
  final Dio _dio;
  ChatRepository(this._dio);

  Future<List<ChatThreadModel>> getThreads() async {
    final response = await _dio.get('/api/chat/threads/').timeout(
          const Duration(seconds: 15),
        );
    final data = response.data;
    final list = data is List ? data : (data['results'] as List? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatThreadModel.fromJson)
        .toList();
  }

  Future<ChatThreadModel> getThreadDetail(int threadId) async {
    final response = await _dio.get('/api/chat/threads/$threadId/').timeout(
          const Duration(seconds: 15),
        );
    return ChatThreadModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> sendMessage(int threadId, String content) async {
    await _dio.post('/api/chat/threads/$threadId/messages/', data: {
      'content': content,
    });
  }

  Future<String> getSocketUrl(int threadId) async {
    final response = await _dio.get('/api/chat/threads/$threadId/socket-auth/').timeout(
          const Duration(seconds: 15),
        );
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['ws_url']?.toString() ?? '';
  }

  Future<ChatThreadModel> startThread(int vendorId, int? productId) async {
    final response = await _dio.post('/api/chat/threads/', data: {
      'vendor_id': vendorId,
      'product_id': productId,
    });
    return ChatThreadModel.fromJson(response.data);
  }
}
