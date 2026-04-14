import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../openai/openai_config.dart';

class DailyThoughtService {
  static const String _keyDate = 'daily_thought_date';
  static const String _keyThought = 'daily_thought_text';

  final AiCompanionClient _aiClient;

  DailyThoughtService({AiCompanionClient? aiClient})
      : _aiClient = aiClient ?? const AiCompanionClient();

  Future<String> getDailyThought() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month}-${now.day}';

      final savedDate = prefs.getString(_keyDate);
      final savedThought = prefs.getString(_keyThought);

      if (savedDate == dateStr && savedThought != null && savedThought.isNotEmpty) {
        return savedThought;
      }

      // Need to fetch a new thought
      final thought = await _fetchNewThought();
      
      await prefs.setString(_keyDate, dateStr);
      await prefs.setString(_keyThought, thought);

      return thought;
    } catch (e) {
      debugPrint('Error getting daily thought: $e');
      return '"The only way out is through."'; // Fallback
    }
  }

  Future<String> _fetchNewThought() async {
    try {
      final messages = [
        const AiChatMessage(
          role: 'system',
          content: 'You are an inspiring therapist. Generate a short, profound, and encouraging daily quote for mental health and personal growth. Output only the quote text.',
        ),
      ];

      final response = await _aiClient.sendChat(messages: messages, model: 'gpt-4o-mini', maxOutputTokens: 100);
      if (response.isNotEmpty) {
        // Ensure it has quotes if not already there, wait, the prompt asks for only the quote text.
        // We'll wrap it in quotes if it doesn't have them.
        String cleanedResponse = response.trim();
        if (!cleanedResponse.startsWith('"')) {
          cleanedResponse = '"$cleanedResponse';
        }
        if (!cleanedResponse.endsWith('"')) {
          cleanedResponse = '$cleanedResponse"';
        }
        return cleanedResponse;
      }
    } catch (e) {
      debugPrint('Failed to generate daily thought from AI: $e');
    }
    return '"The only way out is through."'; // Fallback
  }
}
