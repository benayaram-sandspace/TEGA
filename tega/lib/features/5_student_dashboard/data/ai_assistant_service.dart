import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tega/core/constants/api_constants.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';

class AIAssistantService {
  final AuthService _authService = AuthService();

  Future<AIMessage> sendMessage(String message, {String? sessionId}) async {
    final headers = await _authService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse(ApiEndpoints.chatbotMessage),
      headers: headers,
      body: jsonEncode({
        'message': message,
        if (sessionId != null) 'sessionId': sessionId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final Map<String, dynamic> d = data['data'] as Map<String, dynamic>;
        return AIMessage(
          role: 'assistant',
          content: (d['message'] ?? '').toString(),
          timestamp:
              DateTime.tryParse(d['timestamp']?.toString() ?? '') ??
              DateTime.now(),
          sessionId: d['sessionId']?.toString(),
        );
      }
      throw Exception(data['error'] ?? 'Failed to get AI response');
    }

    throw Exception('Failed to contact AI assistant (${response.statusCode})');
  }
}

class AIMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final String? sessionId;

  AIMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.sessionId,
  });
}
