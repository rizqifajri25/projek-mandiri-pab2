import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_models.dart';
import '../providers/app_providers.dart';
import 'app_shells.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider).value ?? [];
    final messages = ref.watch(adminMessagesProvider).value ?? [];
    final profile = ref.watch(userProfileProvider);

    int count(TaskStatus s) => tasks.where((e) => e.status == s).length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade700, Colors.green.shade400, Colors.white],
            stops: const [.0, .42, 1],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(taskListProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, ${profile.name}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          const Text(
                            'Ringkasan Tugas Hari Ini',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Badge(
                      label: Text('${messages.length}'),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: .22),
                        child: const Icon(Icons.notifications, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _StatusCard(label: 'Total', count: tasks.length, icon: Icons.list_alt, color: Colors.indigo, status: null)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatusCard(label: 'Pending', count: count(TaskStatus.pending), icon: Icons.pending_actions, color: Colors.orange, status: TaskStatus.pending)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatusCard(label: 'Diproses', count: count(TaskStatus.diproses), icon: Icons.sync, color: Colors.blue, status: TaskStatus.diproses)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatusCard(label: 'Selesai', count: count(TaskStatus.selesai), icon: Icons.verified, color: Colors.green, status: TaskStatus.selesai)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('Aktivitas terbaru', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 12),
                ...tasks.take(3).map(
                      (task) => Card(
                        elevation: 0,
                        color: Colors.white.withValues(alpha: .9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(task.status).withValues(alpha: .15),
                            child: Icon(_statusIcon(task.status), color: _statusColor(task.status)),
                          ),
                          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(task.description),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ref.read(taskStatusFilterProvider.notifier).state = task.status;
                            AppShell.openTasks(context);
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.label, required this.count, required this.icon, required this.color, required this.status});

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final TaskStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        ref.read(taskStatusFilterProvider.notifier).state = status;
        AppShell.openTasks(context);
      },
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [color.withValues(alpha: .14), color.withValues(alpha: .05)]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 14),
            Text('$count', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(TaskStatus status) => switch (status) {
      TaskStatus.pending => Colors.orange,
      TaskStatus.diproses => Colors.blue,
      TaskStatus.selesai => Colors.green,
    };

IconData _statusIcon(TaskStatus status) => switch (status) {
      TaskStatus.pending => Icons.pending_actions,
      TaskStatus.diproses => Icons.sync,
      TaskStatus.selesai => Icons.verified,
    };
