import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_models.dart';
import '../providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider).value ?? [];
    final messages = ref.watch(adminMessagesProvider);

    int count(TaskStatus s) => tasks.where((e) => e.status == s).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${messages.length}'),
              child: const Icon(Icons.message),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView(
                  children: messages
                      .map(
                        (m) => ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(m),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(taskListProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Total tugas'),
                trailing: Text('${tasks.length}'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.orange),
                title: const Text('Pending'),
                trailing: Text('${count(TaskStatus.pending)}'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync, color: Colors.blue),
                title: const Text('Diproses'),
                trailing: Text('${count(TaskStatus.diproses)}'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Selesai'),
                trailing: Text('${count(TaskStatus.selesai)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}