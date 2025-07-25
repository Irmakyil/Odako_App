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
  Map<String, AITask?> _selectedTasks = {
    'High': null,
    'Medium': null,
    'Low': null
  };

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
          _errorMessage =
              'No chat history found. Please have a conversation first.';
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
      if (cacheDoc.exists &&
          cacheDoc.data() != null &&
          cacheDoc.data()!['tasks'] != null) {
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
          'tasks':
              tasks.map((e) => {'text': e.text, 'priority': e.priority}).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      setState(() {
        _tasks = tasks;
        _isLoading = false;
        _selectedTasks = {'High': null, 'Medium': null, 'Low': null};
      });
    } catch (e) {
      debugPrint('Error loading/generating tasks: $e'); // Log the actual error
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
    setState(() {
      _isSaving = true;
    });
    try {
      final batch = FirebaseFirestore.instance.batch();
      final tasksCol = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('selectedTasks');
      for (final task in selected) {
        final docRef = tasksCol.doc();
        batch.set(docRef, {
          'text': task.text,
          'priority': task.priority,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
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
      setState(() {
        _isSaving = false;
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color.fromARGB(255, 255, 0, 0);
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return const Color.fromARGB(255, 0, 255, 85);
      default:
        return Colors.grey;
    }
  }

  List<AITask> _tasksForPriority(String priority) {
    return _tasks.where((t) => t.priority.toLowerCase() == priority.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- Full-screen background image ---
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_1.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent, // Make Scaffold background transparent
          // --- App Bar ---
          appBar: AppBar(
            title: Text(
              'Task Suggestions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Transparent AppBar
            elevation: 0, // No shadow for AppBar
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface, // Consistent icon color
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onSurface, // Consistent icon color
                ),
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
                    'Based on your needs, I\'ve generated tasks and broken them into manageable steps. Let\'s get started!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(child: _buildContent()),
                  if (_selectedTasks.values.any((e) => e != null) && !_isLoading)
                    Container(
                      margin: const EdgeInsets.only(top: 24), // Add some space above the button
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSelectedTasks,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // Remove default padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Match MainMenuScreen button radius
                          ),
                          elevation: 5, // Consistent elevation
                          backgroundColor: Colors.transparent, // Transparent for image background
                          shadowColor: Colors.transparent, // Transparent shadow
                          fixedSize: const Size(double.infinity, 45.0), // Consistent height
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage('lib/presentation/assets/na_background_4.png'),
                              fit: BoxFit.fill,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE84797), // Accent color for loading
                                    ),
                                  )
                                : Text(
                                    'Save Selected Tasks',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: const Color.fromARGB(255, 0, 0, 0), // Black text for readability
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFE84797), // Accent color for loading indicator
            ),
            const SizedBox(height: 16),
            Text(
              'Generating tasks from your conversation...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface, // Consistent text color
                  ),
            ),
          ],
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error), // Error icon color
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface, // Consistent text color
                  ),
            ),
            const SizedBox(height: 16),
            // --- Try Again Button ---
            ElevatedButton(
              onPressed: _loadOrGenerateTasks,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                fixedSize: const Size(150, 45.0), // Adjust size for "Try Again"
                visualDensity: VisualDensity.compact,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('lib/presentation/assets/na_background_4.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  alignment: Alignment.center,
                  child: Text(
                    'Try Again',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_tasks.isEmpty) {
      return Center(
          child: Text(
        'No tasks generated. Please try again.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ));
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
                  padding: const EdgeInsets.symmetric(vertical: 12.0), // More vertical padding
                  child: Text(
                    '$priority Priority',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(priority), // Keep dynamic color
                        ),
                  ),
                ),
                // Wrap CheckboxListTile in a Card for better visual separation
                ..._tasksForPriority(priority).map((task) => Card(
                      color: Theme.of(context).colorScheme.surface, // Use theme surface color
                      margin: const EdgeInsets.symmetric(vertical: 6.0), // Spacing between cards
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Rounded corners for cards
                      ),
                      elevation: 2, // Slight elevation for card effect
                      child: CheckboxListTile(
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
                        title: Text(
                          task.text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface, // Consistent text color
                              ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority), // Keep dynamic color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            priority,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith( // Use labelSmall
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // Maintain size for tag
                                ),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFFE84797), // Accent color for checkbox
                        checkColor: Colors.white, // Color of the checkmark
                      ),
                    )),
              ],
            ),
      ],
    );
  }
}