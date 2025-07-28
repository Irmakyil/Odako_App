class AppConstants {
  // App name
  static const String appName = 'Odako';
  
  // Mock user data
  static const String mockUserName = 'Irmak';
  
  // Mock task data
  static const List<Map<String, dynamic>> mockTasks = [
    {
      'id': '1',
      'title': 'Morning routine',
      'time': '09:00',
      'isCompleted': false,
      'type': 'morning',
    },
    {
      'id': '2',
      'title': 'Work on project',
      'time': '10:30',
      'isCompleted': true,
      'type': 'focus',
    },
    {
      'id': '3',
      'title': 'Take a break',
      'time': '12:00',
      'isCompleted': false,
      'type': 'break',
    },
    {
      'id': '4',
      'title': 'Exercise',
      'time': '15:00',
      'isCompleted': false,
      'type': 'activity',
    },
  ];
  
  // Mock mood data
  static const List<Map<String, dynamic>> mockMoods = [
    {
      'id': '1',
      'name': 'Happy',
      'emoji': '😊',
      'color': 0xFF7ED321,
    },
    {
      'id': '2',
      'name': 'Calm',
      'emoji': '😌',
      'color': 0xFF4A90E2,
    },
    {
      'id': '3',
      'name': 'Energetic',
      'emoji': '⚡',
      'color': 0xFFFFD93D,
    },
    {
      'id': '4',
      'name': 'Tired',
      'emoji': '😴',
      'color': 0xFF6C757D,
    },
    {
      'id': '5',
      'name': 'Stressed',
      'emoji': '😰',
      'color': 0xFFE74C3C,
    },
  ];
  
  // Mock weekly mood data for chart
  static const List<Map<String, dynamic>> mockWeeklyMood = [
    {'day': 'Mon', 'mood': 4, 'color': 0xFF7ED321},
    {'day': 'Tue', 'mood': 3, 'color': 0xFF4A90E2},
    {'day': 'Wed', 'mood': 5, 'color': 0xFFFFD93D},
    {'day': 'Thu', 'mood': 2, 'color': 0xFF6C757D},
    {'day': 'Fri', 'mood': 4, 'color': 0xFF7ED321},
    {'day': 'Sat', 'mood': 5, 'color': 0xFFFFD93D},
    {'day': 'Sun', 'mood': 3, 'color': 0xFF4A90E2},
  ];
  
  // Navigation delays
  static const int splashDelay = 2000; // 2 seconds
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
