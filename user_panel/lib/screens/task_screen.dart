import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Tugas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari tugas / lokasi',
                prefixIcon: Icon(Icons.search),
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
                    .where((t) =>
                        t.title.toLowerCase().contains(query.toLowerCase()) ||
                        t.description.toLowerCase().contains(query.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) return const EmptyState('Tidak ada tugas');

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(taskListProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      return Card(
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VerificationScreen(task: t)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(t.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                              ),
                              ListTile(
                                title: Text(t.title),
                                subtitle: Text(t.description),
                                trailing: Chip(label: Text(t.status.name.toUpperCase())),
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
    );
  }
}