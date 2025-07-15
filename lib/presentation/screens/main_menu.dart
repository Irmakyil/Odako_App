import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  // Mock user and task data
  final String _username = 'xxx';
  final double _progress = 0.25; // 25%
  final List<String> _tasks = const [
    'Review today\'s goals',
    'Complete 1 Pomodoro',
    'Take a 5-minute break',
    'Check in with your mood',
    'Plan tomorrow\'s top task',
  ];
  final String _activeTask = 'Complete 1 Pomodoro';

  @override
  Widget build(BuildContext context) {
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
              // Welcome
              Text(
                'Hi $_username!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              // Daily Progress
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Text('📈', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Progress', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 8),
                            Text('${(_progress * 100).round()}%  Almost There!', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Today's Task List Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today\'s Tasks', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.taskList);
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length > 3 ? 3 : _tasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(_tasks[index], style: Theme.of(context).textTheme.bodyLarge),
                      onTap: () {
                        // Optionally expand or navigate to details
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Active Task Highlight
              Text('Active Task', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Text('🔄', style: TextStyle(fontSize: 28)),
                  title: Text(_activeTask, style: Theme.of(context).textTheme.bodyLarge),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Start focus mode (future)
                    },
                    child: const Text('Focus'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Mascot or illustration placeholder
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text('🐙', style: TextStyle(fontSize: 56)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Stick close with me!', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
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
