import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Map<int, String> moodPrompts = {
  0: "I'm feeling down today. ",
  1: "I'm feeling okay, but not great today. ",
  2: "I'm feeling great today! ",
};

class AIService {
  static const String _geminiApiKey = '';
  static const String _geminiApiUrl = ''; 

  static Future<Map<String, dynamic>?> fetchUserProfile({String? uid}) async {
    try {
      final userId = uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final profileSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .get();

      return profileSnapshot.data();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<String> getDailyTaskSuggestion(String userInput, {int? moodIndex}) async {
    final moodPrompt = moodIndex != null && moodPrompts.containsKey(moodIndex)
        ? moodPrompts[moodIndex]!
        : '';

    String userInfo = '';
    try {
      final data = await fetchUserProfile();
      final username = (data?['username']?.toString().isNotEmpty ?? false) ? data!['username'] : 'User';
      userInfo = 'User profile → Name: $username';

      if (data?['age'] != null) userInfo += ', Age: ${data!['age']}';
      if (data?['gender']?.toString().isNotEmpty ?? false) userInfo += ', Gender: ${data!['gender']}';
      if (data?['adhdType']?.toString().isNotEmpty ?? false) userInfo += ', ADHD Type: ${data!['adhdType']}';

      userInfo += '.';
    } catch (e) {
      debugPrint('Error fetching user profile for AI prompt: $e');
      userInfo = '';
    }

    final prompt = '''
You are a friendly and motivational assistant helping someone (the user) with ADHD plan their day. 
${userInfo.isNotEmpty ? "$userInfo\n" : ''}
Today, the user feels: $moodPrompt
This is the user's input: "$userInput". It's either a task they want to accomplish or just their thoughts and emotions. 
Change your tone, manner and how you speak and give appropriate responses to the user according to user's ADHD type (if it is not "Not Sure"), age and gender.
If it is a task, suggest a short and simple first step related to what they want to accomplish. Be concise and direct. 
If the user is just sharing their thoughts and emotions, have a conversation with them and support them.
''';

    return await _postToGeminiApi(prompt) ?? "Try breaking it into small steps";
  }

  static Future<String> getTasksFromChatContext(String chatContext) async {
    final prompt = '''
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

    return await _postToGeminiApi(prompt) ??
        '''[
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

  static Future<String> sendMessageToGemini(String userMessage) async {
    String username = 'User';
    try {
      final data = await fetchUserProfile();
      if (data?['username']?.toString().isNotEmpty ?? false) {
        username = data!['username'];
      }
    } catch (e) {
      debugPrint('Error fetching username for chat: $e');
    }

    final prompt = 'The user\'s name is "$username". When you refer to the user, use their name instead of generic terms like \'User\'.\n$userMessage';

    return await _postToGeminiApi(prompt) ?? "Sorry, I couldn't process that right now.";
  }

  // Helper method to post request to Gemini API and parse response
  static Future<String?> _postToGeminiApi(String prompt) async {
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
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      } else {
        debugPrint('Gemini API Error: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini API exception: $e');
    }
    return null;
  }
}