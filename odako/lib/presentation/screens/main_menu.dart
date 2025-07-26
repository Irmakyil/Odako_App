import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../widgets/daily_progress_circle.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Future<String> _fetchUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'User';
      final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('data')
        .get();
      final data = doc.data();
      final username = (data != null && data['username'] != null && data['username'].toString().isNotEmpty)
        ? data['username']
        : null;
      return username ?? 'User';
    } catch (e) {
      debugPrint('Error fetching username: $e');
      return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            title: const Text('Odako'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
                    future: _fetchUsername(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 12),
                            Text('Hi...', style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        );
                      }
                      final username = snapshot.data ?? 'User';
                      return Row(
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
                          const DailyProgressCircle(size: 56, showLabel: false),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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
                  Builder(
                    builder: (context) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        return const Center(child: Text('Please sign in.'));
                      }
                      final now = DateTime.now();
                      final twentyFourHoursAgo = Timestamp.fromDate(
                        now.subtract(const Duration(hours: 24)),
                      );
                      final stream = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text('No high-priority tasks for today.');
                          }

                          final doc = snapshot.data!.docs.first;
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color:
                                          isCompleted ? Colors.grey : null,
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
                  const OpenChatSection(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
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
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: Image.asset('lib/presentation/assets/home.png', width: 50, height: 50),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset('lib/presentation/assets/task.png', width: 50, height: 50),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Image.asset('lib/presentation/assets/profile.png', width: 50, height: 50),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OpenChatSection extends StatelessWidget {
  const OpenChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            'Talk to me!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              SizedBox(
                height: 250,
                width: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'lib/presentation/assets/chatbox2_variant.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'lib/presentation/assets/maskot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              ElevatedButton(
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
                  fixedSize: Size(125.0, 45.0),
                  visualDensity: VisualDensity.compact,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/presentation/assets/na_background_4.png'),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    alignment: Alignment.center,
                    child: const Text(
                      'Open Chat',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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