import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/daily_progress_circle.dart';

/// Main menu screen showing welcome, progress, today's task, and navigation
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username =
        user?.displayName ?? (user?.email?.split('@').first ?? 'User');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odako'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome and progress row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Hi $username!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Circular progress bar
                  const DailyProgressCircle(size: 56, showLabel: false),
                ],
              ),
              const SizedBox(height: 24),
              // Today's task list preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Tasks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.taskList);
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // High priority task preview (shows only one)
              Builder(
                builder: (context) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    return const Center(child: Text('No tasks yet.'));
                  }
                  final now = DateTime.now();
                  final twentyFourHoursAgo = Timestamp.fromDate(
                    now.subtract(const Duration(hours: 24)),
                  );
                  final stream = FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('selectedTasks')
                      .where('priority', isEqualTo: 'High')
                      .where(
                        'createdAt',
                        isGreaterThanOrEqualTo: twentyFourHoursAgo,
                      )
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .snapshots();
                  return StreamBuilder<QuerySnapshot>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text('No tasks yet.');
                      }
                      final doc = docs.first;
                      final data = doc.data() as Map<String, dynamic>;
                      final isCompleted = data['isCompleted'] == true;
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: isCompleted,
                            onChanged: (_) async {
                              await doc.reference.update({
                                'isCompleted': !isCompleted,
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          title: Text(
                            data['text'] ?? '',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted ? Colors.grey : null,
                                ),
                          ),
                          subtitle: data['priority'] != null
                              ? Text('Priority: ${data['priority']}')
                              : null,
                          onTap: () async {
                            await doc.reference.update({
                              'isCompleted': !isCompleted,
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              // Section for chat support
              const OpenChatSection(),
            ],
          ),
        ),
      ),
      // Bottom navigation bar for main navigation
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushNamed(context, AppRoutes.taskList);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
            case 0:
            default:
              // Home, do nothing or pop to root if needed
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

/// Section for opening the chat if the user feels anxious
class OpenChatSection extends StatelessWidget {
  const OpenChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            'If you are anxious talk to me!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Container(
                height: 200,
                width: 200,
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
