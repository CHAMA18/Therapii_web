import 'dart:async';

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

const apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class AiChatException implements Exception {
  AiChatException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode != null ? 'AiChatException($statusCode): $message' : 'AiChatException: $message';
}

class AiCompanionClient {
  const AiCompanionClient();

  Future<String> sendChat({
    required List<AiChatMessage> messages,
    String model = 'gpt-4o',
    int maxOutputTokens = 2000,
    bool preferChatCompletions = false,
    String? agentWorkflowId = 'wf_69dd97fad7988190849d59cdf5e8197d076f6affb8c2ec8c',
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in sendChatStream(
      messages: messages,
      model: model,
      maxOutputTokens: maxOutputTokens,
      preferChatCompletions: preferChatCompletions,
      agentWorkflowId: agentWorkflowId,
    )) {
      buffer.write(chunk);
    }

    final response = buffer.toString().trim();
    if (response.isEmpty) {
      throw AiChatException('The AI companion returned an empty response.');
    }
    return response;
  }

  Future<Uint8List> generateSpeech(String text, {String voice = 'alloy', String model = 'tts-1'}) async {
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw AiChatException('OpenAI proxy is not configured.');
    }

    final ttsEndpoint = endpoint.replaceAll('chat/completions', 'audio/speech');
    final uri = Uri.parse(ttsEndpoint);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'input': text,
        'voice': voice,
        'response_format': 'mp3',
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw AiChatException('Failed to generate speech: ${response.statusCode} - ${response.body}', statusCode: response.statusCode);
    }
  }

  Stream<String> sendChatStream({
    required List<AiChatMessage> messages,
    String model = 'gpt-4o',
    int maxOutputTokens = 2000,
    bool preferChatCompletions = false,
    String? agentWorkflowId = 'wf_69dd97fad7988190849d59cdf5e8197d076f6affb8c2ec8c',
  }) async* {
    if (messages.isEmpty) {
      throw AiChatException('At least one message is required to contact the AI companion.');
    }

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateAiChatCompletion');
      
      // ignore: avoid_print
      print('[AI] Calling Cloud Function: generateAiChatCompletion');
      
      final result = await callable.call({
        'messages': messages.map((m) => m.toJson()).toList(),
        'model': model,
        'maxOutputTokens': maxOutputTokens,
        if (agentWorkflowId != null) 'agentWorkflowId': agentWorkflowId,
      });

      final data = result.data;
      if (data is Map) {
        final text = data['text'];
        if (text is String && text.trim().isNotEmpty) {
          // ignore: avoid_print
          print('[AI] Cloud Function returned text length: ${text.length}');
          yield text.trim();
          return;
        }
      }

      throw AiChatException('The AI companion returned an empty response.');
    } on FirebaseFunctionsException catch (e) {
      // ignore: avoid_print
      print('[AI] Cloud Function error: code=${e.code} message=${e.message}');
      
      final message = e.message ?? 'Failed to contact the AI companion.';
      
      // Check if this is a configuration error
      if (message.contains('not configured') || message.contains('API key')) {
        throw AiChatException('AI companion not configured. Admin users can configure it in Settings > Admin Settings.');
      }
      
      throw AiChatException(message);
    } on TimeoutException {
      throw AiChatException('The AI companion is taking too long to respond. Please try again.');
    } catch (error) {
      // ignore: avoid_print
      print('[AI] Unexpected error: $error');
      throw AiChatException('Unexpected error while contacting the AI companion: $error');
    }
  }
}

List<AiChatMessage> buildCompanionMessages({
  required String userMessage,
  required List<AiChatMessage> history,
  String? systemPrompt,
}) {
  final messages = <AiChatMessage>[];
  if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
    messages.add(AiChatMessage(role: 'system', content: systemPrompt.trim()));
  }
  messages.addAll(history);
  messages.add(AiChatMessage(role: 'user', content: userMessage));
  return messages;
}