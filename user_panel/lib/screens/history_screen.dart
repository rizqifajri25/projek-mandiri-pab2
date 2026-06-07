import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(verificationHistoryProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Verifikasi')),
      body: history.isEmpty
          ? const Center(child: Text('Belum ada riwayat verifikasi'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (_, i) {
                final h = history[i];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (h.photoPath != null)
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            h.photoPath!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ListTile(
                        title: Text(h.taskTitle),
                        subtitle: Text('Task ID: ${h.taskId}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lokasi: ${h.latitude}, ${h.longitude}'),
                            Text('Selesai: ${dateFormat.format(h.completedAt)}'),
                            Text('Durasi: ${h.completionDuration.inMinutes} menit'),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}