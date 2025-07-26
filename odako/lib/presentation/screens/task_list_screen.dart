import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/daily_progress_circle.dart';
import '../../services/gamification_service.dart';
import '../../routes/app_routes.dart'; // Import AppRoutes for navigation

/// Model representing a task (remains unchanged as it's a data model)
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
        // "Talk to me!" text
        Center(
          child: Text(
            'Talk to me!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface, // Consistent text color
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16), // Adjusted spacing
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
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.chat);
                  },
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final twentyFourHoursAgo = Timestamp.fromDate(now.subtract(const Duration(hours: 24)));

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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
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
                    stream: FirebaseAuth.instance.currentUser == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('selectedTasks')
                            .where('createdAt', isGreaterThanOrEqualTo: twentyFourHoursAgo)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.secondary,
                        ));
                      }
                      if (snapshot.hasError) {
                        debugPrint('Error fetching tasks: ${snapshot.error}');
                        return Center(
                            child: Text(
                          'Error loading tasks. Please try again.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ));
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                            child: Text(
                          'No tasks yet. Start a conversation with me to get some!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ));
                      }
                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isCompleted = data['isCompleted'] == true;
                          return Card(
                            color: Theme.of(context).colorScheme.surface,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: Checkbox(
                                value: isCompleted,
                                onChanged: (_) async {
                                  await doc.reference.update({'isCompleted': !isCompleted});
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
                                        final completedToday = tasksSnap.docs.where((d) => (d['isCompleted'] ?? false) == true).length;
                                        await GamificationService().onTaskCompleted(
                                          completedAt: DateTime.now(),
                                          totalTasksToday: completedToday + 1,
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Gamification error: $e');
                                    }
                                  }
                                },
                                activeColor: Theme.of(context).colorScheme.secondary,
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              title: Text(
                                data['text'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      color: isCompleted
                                          ? Theme.of(context).colorScheme.onSurface 
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              subtitle: data['priority'] != null
                                  ? Text(
                                      'Priority: ${data['priority']}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                    )
                                  : null,
                              onTap: () async {
                                await doc.reference.update({'isCompleted': !isCompleted});
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
                                      final completedToday = tasksSnap.docs.where((d) => (d['isCompleted'] ?? false) == true).length;
                                      await GamificationService().onTaskCompleted(
                                        completedAt: DateTime.now(),
                                        totalTasksToday: completedToday + 1,
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
                const SizedBox(height: 24),
                const OpenChatSection(),
              ],
            ),
          ),
          floatingActionButton: null,
        ),
      ],
    );
  }
}