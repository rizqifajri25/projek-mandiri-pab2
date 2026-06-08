import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projek_tugas_mandiri/models/task_models.dart' show TaskStatus;
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import 'verification_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String query = '';
  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskListProvider);
    final selectedStatus = ref.watch(taskStatusFilterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Tugas'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.green.shade400]),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari tugas / lokasi',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const AppSkeleton(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (tasks) {
                final filtered = tasks
                    .where((t) => selectedStatus == null || t.status == selectedStatus)
                    .where((t) =>
                        t.title.toLowerCase().contains(query.toLowerCase()) ||
                        t.description.toLowerCase().contains(query.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) return const EmptyState('Tidak ada tugas');

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(taskListProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length + (selectedStatus == null ? 0 : 1),
                    itemBuilder: (_, i) {
                      if (selectedStatus != null && i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InputChip(
                            avatar: const Icon(Icons.filter_alt, size: 18),
                            label: Text(
                              'Filter: ${taskStatusText(selectedStatus).toUpperCase()}',
                            ),
                            onDeleted: () => ref.read(taskStatusFilterProvider.notifier).state = null,
                          ),
                        );
                      }
                      final t = filtered[selectedStatus == null ? i : i - 1];
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VerificationScreen(task: t)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.network(t.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                              ),
                              ListTile(
                                title: Text(t.title),
                                subtitle: Text(t.description),
                                trailing: Chip(
                                  backgroundColor: _statusColor(t.status).withValues(alpha: .14),
                                  label: Text(taskStatusText(t.status), style: TextStyle(color: _statusColor(t.status), fontWeight: FontWeight.w800)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Lokasi: ${t.latitude}, ${t.longitude}'),
                                    Text('Mulai: ${dateFormat.format(t.startAt)}'),
                                    Text('Deadline: ${dateFormat.format(t.dueAt)}'),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
      ),
    );
  }
}

String taskStatusText(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return 'pending';
    case TaskStatus.diproses:
      return 'diproses';
    case TaskStatus.selesai:
      return 'selesai';
  }
}

Color _statusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return Colors.orange;
    case TaskStatus.diproses:
      return Colors.blue;
    case TaskStatus.selesai:
      return Colors.green;
  }
}
