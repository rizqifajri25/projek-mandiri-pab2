import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'task_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void openTasks(BuildContext context) {
    context.findAncestorStateOfType<_AppShellState>()?.setIndex(1);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  void setIndex(int value) => setState(() => index = value);

  final pages = const [
    DashboardScreen(),
    TasksScreen(),
    HistoryScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 72,
        indicatorColor: Colors.teal.shade100,
        onDestinationSelected: setIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'Tugas'),
          NavigationDestination(icon: Icon(Icons.history_toggle_off), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Notifikasi'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
