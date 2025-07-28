import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/daily_progress_circle.dart';
import '../../services/gamification_service.dart';
import '../../routes/app_routes.dart';

class Task {
  final String title;
  final String? emoji;
  bool isCompleted;
  Task({required this.title, this.emoji, this.isCompleted = false});
}

class OpenChatSection extends StatelessWidget {
  const OpenChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Center(
          child: Text(
            'Talk to me!',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('lib/presentation/assets/chatbox2_variant.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'lib/presentation/assets/maskot.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    fixedSize: const Size(double.infinity, 45.0),
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
                      child: Text(
                        'Open Chat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w600,
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
      ],
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final now = DateTime.now();

  Timestamp get twentyFourHoursAgo => Timestamp.fromDate(now.subtract(const Duration(hours: 24)));

  Future<void> _handleTaskCompletion(DocumentReference docRef, bool currentStatus) async {
    await docRef.update({'isCompleted': !currentStatus});

    if (!currentStatus) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final tasksSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('selectedTasks')
            .where('createdAt', isGreaterThanOrEqualTo: twentyFourHoursAgo)
            .get();

        final completedToday = tasksSnap.docs.where((d) => (d['isCompleted'] ?? false) == true).length;

        await GamificationService().onTaskCompleted(
          completedAt: DateTime.now(),
          totalTasksToday: completedToday + 1,
        );
      } catch (e) {
        debugPrint('Gamification error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final user = FirebaseAuth.instance.currentUser;
    final tasksStream = user == null
        ? null
        : FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('selectedTasks')
            .where('createdAt', isGreaterThanOrEqualTo: twentyFourHoursAgo)
            .snapshots();

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
              'Your Tasks',
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
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'You got this! Keep on trucking!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const DailyProgressCircle(size: 48, showLabel: false),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: tasksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: theme.colorScheme.secondary),
                        );
                      }
                      if (snapshot.hasError) {
                        debugPrint('Error fetching tasks: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'Error loading tasks. Please try again.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No tasks yet. Start a conversation with me to get some!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data()! as Map<String, dynamic>;
                          final isCompleted = data['isCompleted'] == true;

                          return Card(
                            color: theme.colorScheme.surface,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: Checkbox(
                                value: isCompleted,
                                onChanged: (_) => _handleTaskCompletion(doc.reference, isCompleted),
                                activeColor: theme.colorScheme.secondary,
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              title: Text(
                                data['text'] ?? '',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: data['priority'] != null
                                  ? Text(
                                      'Priority: ${data['priority']}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    )
                                  : null,
                              onTap: () => _handleTaskCompletion(doc.reference, isCompleted),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const OpenChatSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}