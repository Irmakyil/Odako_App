import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/daily_progress_circle.dart';
import '../../services/gamification_service.dart';

/// Model representing a task
class Task {
  final String title;
  final String? emoji;
  bool isCompleted;
  Task({required this.title, this.emoji, this.isCompleted = false});
}

/// Section for opening the chat if the user feels anxious
class OpenChatSection extends StatelessWidget {
  const OpenChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text('If you are anxious talk to me!', style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.primary.withAlpha(20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(60),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withAlpha(20),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    'lib/presentation/assets/mantar_maskot.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
                child: const Text('Open Chat'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Main screen displaying the user's task list and progress
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final twentyFourHoursAgo = Timestamp.fromDate(now.subtract(const Duration(hours: 24)));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress and encouragement row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'You are doing well! Keep pushing!',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const DailyProgressCircle(size: 48, showLabel: false),
              ],
            ),
            const SizedBox(height: 16),
            // Task list section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseAuth.instance.currentUser == null
                    ? null
                    : FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('selectedTasks')
                        .where('createdAt', isGreaterThanOrEqualTo: twentyFourHoursAgo)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No tasks yet.'));
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isCompleted = data['isCompleted'] == true;
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: Checkbox(
                            value: isCompleted,
                            onChanged: (_) async {
                              await doc.reference.update({'isCompleted': !isCompleted});
                              // Gamification logic: only when marking as completed
                              if (!isCompleted) {
                                try {
                                  // Count completed tasks today after this one
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    final now = DateTime.now();
                                    final twentyFourHoursAgo = Timestamp.fromDate(now.subtract(const Duration(hours: 24)));
                                    final tasksSnap = await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('selectedTasks')
                                        .where('createdAt', isGreaterThanOrEqualTo: twentyFourHoursAgo)
                                        .get();
                                    final completedToday = tasksSnap.docs.where((d) => (d['isCompleted'] ?? false) == true).length + 1;
                                    await GamificationService().onTaskCompleted(
                                      priority: data['priority'] ?? 'Low',
                                      completedAt: DateTime.now(),
                                      totalTasksToday: completedToday,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Gamification error: $e');
                                }
                              }
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          title: Text(
                            data['text'] ?? '',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? Colors.grey : null,
                                ),
                          ),
                          subtitle: data['priority'] != null ? Text('Priority: ${data['priority']}') : null,
                          onTap: () async {
                            await doc.reference.update({'isCompleted': !isCompleted});
                            // Gamification logic: only when marking as completed
                            if (!isCompleted) {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  final now = DateTime.now();
                                  final twentyFourHoursAgo = Timestamp.fromDate(now.subtract(const Duration(hours: 24)));
                                  final tasksSnap = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('selectedTasks')
                                      .where('createdAt', isGreaterThanOrEqualTo: twentyFourHoursAgo)
                                      .get();
                                  final completedToday = tasksSnap.docs.where((d) => (d['isCompleted'] ?? false) == true).length + 1;
                                  await GamificationService().onTaskCompleted(
                                    priority: data['priority'] ?? 'Low',
                                    completedAt: DateTime.now(),
                                    totalTasksToday: completedToday,
                                  );
                                }
                              } catch (e) {
                                debugPrint('Gamification error: $e');
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Section for chat support
            const OpenChatSection(),
          ],
        ),
      ),
      floatingActionButton: null, // No add task button for selected tasks only
    );
  }
}
