import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_service.dart';
import '../../services/task_service.dart';
import '../../data/models/ai_task.dart';

class SuggestBreakdownScreen extends StatefulWidget {
  const SuggestBreakdownScreen({super.key});

  @override
  State<SuggestBreakdownScreen> createState() => _SuggestBreakdownScreenState();
}

class _SuggestBreakdownScreenState extends State<SuggestBreakdownScreen> {
  List<AITask> _tasks = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _sessionId;
  Map<String, AITask?> _selectedTasks = {'High': null, 'Medium': null, 'Low': null};

  @override
  void initState() {
    super.initState();
    _loadOrGenerateTasks();
  }

  Future<void> _loadOrGenerateTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      // 1. Get latest session
      final sessionsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('chat_sessions')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (sessionsQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No chat history found. Please have a conversation first.';
          _isLoading = false;
        });
        return;
      }
      final latestSession = sessionsQuery.docs.first;
      _sessionId = latestSession.id;
      // 2. Check cache
      final cacheDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('cachedTasks')
          .doc(_sessionId)
          .get();
      List<AITask> tasks;
      if (cacheDoc.exists && cacheDoc.data() != null && cacheDoc.data()!['tasks'] != null) {
        // Use cached
        final cachedList = List<Map<String, dynamic>>.from(cacheDoc.data()!['tasks']);
        tasks = cachedList.map((e) => AITask.fromJson(e)).toList();
      } else {
        // 3. Get messages for context
        final messagesQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('chat_sessions')
            .doc(_sessionId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .get();
        if (messagesQuery.docs.isEmpty) {
          setState(() {
            _errorMessage = 'No chat messages found.';
            _isLoading = false;
          });
          return;
        }
        final contextBuilder = StringBuffer();
        for (final doc in messagesQuery.docs) {
          final data = doc.data();
          final sender = data['sender'] as String;
          final message = data['message'] as String;
          contextBuilder.writeln('$sender: $message');
        }
        final chatContext = contextBuilder.toString();
        // 4. Call AI
        final aiResponse = await AIService.getTasksFromChatContext(chatContext);
        tasks = TaskService.parseAITasksFromJson(aiResponse);
        // 5. Cache result
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('cachedTasks')
            .doc(_sessionId)
            .set({
          'sessionId': _sessionId,
          'tasks': tasks.map((e) => {'text': e.text, 'priority': e.priority}).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      setState(() {
        _tasks = tasks;
        _isLoading = false;
        _selectedTasks = {'High': null, 'Medium': null, 'Low': null};
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate tasks. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedTasks() async {
    if (_sessionId == null) return;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final selected = _selectedTasks.values.where((e) => e != null).cast<AITask>().toList();
    if (selected.isEmpty) return;
    setState(() { _isSaving = true; });
    try {
      final batch = FirebaseFirestore.instance.batch();
      final tasksCol = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks');
      for (final task in selected) {
        final docRef = tasksCol.doc();
        batch.set(docRef, {
          'text': task.text,
          'priority': task.priority,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'AI',
          'sessionId': _sessionId,
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tasks saved!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  List<AITask> _tasksForPriority(String priority) {
    return _tasks.where((t) => t.priority.toLowerCase() == priority.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-Powered Task Suggestions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadOrGenerateTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on your daily input, we\'ve generated tasks and broken them into manageable steps. Let\'s get started!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Expanded(child: _buildContent()),
              if (_selectedTasks.values.any((e) => e != null) && !_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSelectedTasks,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Selected Tasks'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating tasks from your conversation...'),
          ],
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOrGenerateTasks, child: const Text('Try Again')),
          ],
        ),
      );
    }
    if (_tasks.isEmpty) {
      return const Center(child: Text('No tasks generated. Please try again.'));
    }
    // Group by priority and allow selection
    return ListView(
      children: [
        for (final priority in ['High', 'Medium', 'Low'])
          if (_tasksForPriority(priority).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('$priority Priority', style: TextStyle(fontWeight: FontWeight.bold, color: _getPriorityColor(priority))),
                ),
                ..._tasksForPriority(priority).map((task) => CheckboxListTile(
                  value: _selectedTasks[priority]?.text == task.text,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedTasks[priority] = task;
                      } else {
                        _selectedTasks[priority] = null;
                      }
                    });
                  },
                  title: Text(task.text),
                  secondary: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(priority, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                )),
              ],
            ),
      ],
    );
  }
} 