import 'package:flutter/material.dart';

class Task {
  final String title;
  final String? emoji;
  bool isCompleted;
  Task({required this.title, this.emoji, this.isCompleted = false});
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<Task> _tasks = [
    Task(title: 'Review today\'s goals', emoji: '📝'),
    Task(title: 'Complete 1 Pomodoro', emoji: '⏰'),
    Task(title: 'Take a 5-minute break', emoji: '☕'),
    Task(title: 'Check in with your mood', emoji: '🙂'),
    Task(title: 'Plan tomorrow\'s top task', emoji: '📅'),
  ];

  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  void _addTask() {
    setState(() {
      _tasks.add(Task(title: 'New Task', emoji: '✨'));
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Text('You are doing well! Keep pushing!', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _tasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Text(task.emoji ?? '✅', style: const TextStyle(fontSize: 28)),
                      title: Text(
                        task.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                      ),
                      trailing: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => _toggleTask(index),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onTap: () => _toggleTask(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('If you are anxious talk to me!', style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🐙', style: TextStyle(fontSize: 36)),
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
