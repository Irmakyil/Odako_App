import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

final Map<int, String> moodPrompts = {
  0: "I'm feeling down today. ",
  1: "I'm feeling okay, but not great today. ",
  2: "I'm feeling great today! ",
};

class AIService {
  static const String _geminiApiKey = '';
  static const String _geminiApiUrl = '';  

  static Future<String> getDailyTaskSuggestion(
    String userInput, {
    int? moodIndex,
  }) async {
    final moodPrompt = (moodIndex != null && moodPrompts.containsKey(moodIndex))
        ? moodPrompts[moodIndex]!
        : '';
    final prompt =
        'You are a friendly and motivational assistant helping someone with ADHD plan their day. '
        '$moodPrompt'
        'This is the user\'s input: "$userInput". It\'s either a task they want to accomplish or just their thoughts and emotions.'
        'If it is a task, suggest a short and simple first step related to what they want to accomplish. Be concise and direct. If the user is just sharing their thoughts and emotions, have a conversation with them and support them.';

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
                {'text': prompt},
              ],
            },
          ],
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
    final prompt =
        '''
You are a friendly and motivational assistant helping someone with ADHD break down their task into manageable steps.

Based on this conversation:
$chatContext

Generate a JSON response with an array of tasks. Each task should have:
- "text": A clear and short, actionable description
- "priority": One of ["High", "Medium", "Low"]

Focus on:
1. Breaking large task into smaller, manageable steps
2. Prioritizing tasks based on importance and urgency (Keep in mind that ADHD users may struggle with prioritization)
3. Making tasks specific and actionable
4. Considering ADHD-friendly task sizes

Return valid JSON formatting like this:
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
                {'text': prompt},
              ],
            },
          ],
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

  /// Sends a user message to Gemini and returns the AI reply for chat. for chat_screen.dart
  static Future<String> sendMessageToGemini(String userMessage) async {
    final prompt = userMessage;
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
                {'text': prompt},
              ],
            },
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      } else {
        debugPrint('Gemini API Error: \\${response.statusCode}');
        debugPrint('Body: \\${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini API exception: $e');
    }
    return "Sorry, I couldn't process that right now.";
  }
}
