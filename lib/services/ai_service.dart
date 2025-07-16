import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _geminiApiKey = 'AIzaSyBj-AeElRI9QL2J7NBIQA4HpJ_QgKDNm6o';
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String> getDailyTaskSuggestion(String userInput) async {
    final prompt =
        'You are a friendly and motivational assistant helping someone with ADHD plan their day. '
        'The user wants to accomplish the following goal: "$userInput". '
        'Suggest a simple, encouraging first step. Be concise and positive.';

    try {
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      } else {
        // Log error for debugging
        debugPrint('Gemini API Error: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini API exception: $e');
    }

    await Future.delayed(const Duration(seconds: 1));
    return "Try breaking it into small steps";
  }

  /// Generates structured tasks from chat context
  /// 
  /// [chatContext] - The full conversation history as a string
  /// Returns a JSON string with structured tasks
  static Future<String> getTasksFromChatContext(String chatContext) async {
    final prompt = '''
You are an AI assistant helping someone with ADHD break down their goals into manageable tasks.

Based on this conversation:
$chatContext

Generate a JSON response with an array of tasks. Each task should have:
- "text": A clear, actionable description
- "priority": One of ["High", "Medium", "Low"]

Focus on:
1. Breaking large goals into smaller, manageable steps
2. Prioritizing tasks based on importance and urgency
3. Making tasks specific and actionable
4. Considering ADHD-friendly task sizes

Return ONLY valid JSON like this:
[
  {
    "text": "Make your bed",
    "priority": "High"
  },
  {
    "text": "Organize your desk",
    "priority": "Medium"
  }
]
''';

    try {
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      } else {
        debugPrint('Gemini API Error: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini API exception: $e');
    }

    // Fallback response if API fails
    return '''[
  {
    "text": "Break down your main goal into smaller steps",
    "priority": "High"
  },
  {
    "text": "Set a specific time to start each task",
    "priority": "Medium"
  }
]''';
  }
}
