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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      // En son chat session
      final sessionsQuery = await userRef
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

      final cacheDoc = await userRef.collection('cachedTasks').doc(_sessionId).get();

      List<AITask> tasks;

      if (cacheDoc.exists && cacheDoc.data()?['tasks'] != null) {
        final cachedList = List<Map<String, dynamic>>.from(cacheDoc.data()!['tasks']);
        tasks = cachedList.map(AITask.fromJson).toList();
      } else {
        final messagesQuery = await userRef
            .collection('chat_sessions')
            .doc(_sessionId)
            .collection('messages')
            .orderBy('timestamp')
            .get();

        if (messagesQuery.docs.isEmpty) {
          setState(() {
            _errorMessage = 'No chat messages found.';
            _isLoading = false;
          });
          return;
        }

        final chatContext = messagesQuery.docs
            .map((doc) {
              final data = doc.data();
              return '${data['sender']}: ${data['message']}';
            })
            .join('\n');

        final aiResponse = await AIService.getTasksFromChatContext(chatContext);
        tasks = TaskService.parseAITasksFromJson(aiResponse);

        await userRef.collection('cachedTasks').doc(_sessionId).set({
          'sessionId': _sessionId,
          'tasks': tasks.map((e) => {'text': e.text, 'priority': e.priority}).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _tasks = tasks;
        _selectedTasks = {'High': null, 'Medium': null, 'Low': null};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading/generating tasks: $e');
      setState(() {
        _errorMessage = 'Failed to generate tasks. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedTasks() async {
    if (_sessionId == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final selected = _selectedTasks.values.whereType<AITask>().toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final tasksCol = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('selectedTasks');

      final batch = FirebaseFirestore.instance.batch();

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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasks saved!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  List<AITask> _tasksForPriority(String priority) =>
      _tasks.where((t) => t.priority.toLowerCase() == priority.toLowerCase()).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/presentation/assets/na_background_1.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Task Suggestions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                onPressed: _isLoading ? null : _loadOrGenerateTasks,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Based on your needs, I've generated tasks and broken them into manageable steps. Let's get started!",
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 32),
                  Expanded(child: _buildContent()),
                  if (_selectedTasks.values.any((e) => e != null) && !_isLoading)
                    _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSelectedTasks,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          fixedSize: const Size(double.infinity, 45),
          visualDensity: VisualDensity.compact,
        ),
        child: Ink(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('lib/presentation/assets/Button.png'),
              fit: BoxFit.cover,
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
                      color: Color(0xFFE84797),
                    ),
                  )
                : Text(
                    'Save Selected Tasks',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFE84797)),
            const SizedBox(height: 16),
            Text(
              'Generating tasks from your conversation...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
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
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrGenerateTasks,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                fixedSize: const Size(150, 45),
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.black,
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
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
        ),
      );
    }

    return ListView(
      children: ['High', 'Medium', 'Low']
          .where((priority) => _tasksForPriority(priority).isNotEmpty)
          .map(
            (priority) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '$priority Priority',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ),
                ..._tasksForPriority(priority).map(
                  (task) => Card(
                    color: theme.colorScheme.surface,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: CheckboxListTile(
                      value: _selectedTasks[priority]?.text == task.text,
                      onChanged: (selected) {
                        setState(() {
                          _selectedTasks[priority] = selected == true ? task : null;
                        });
                      },
                      title: Text(
                        task.text,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                      secondary: Container(
                        width: 120,
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('lib/presentation/assets/${priority.toLowerCase()}.png'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          priority,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _getPriorityColor(priority),
                      checkColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}