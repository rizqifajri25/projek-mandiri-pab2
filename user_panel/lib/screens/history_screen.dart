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
      appBar: AppBar(title: const Text('History Percobaan Tugas')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade50, Colors.green.shade50, Colors.white],
          ),
        ),
        child: history.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 88, color: Colors.teal.shade300),
                      const SizedBox(height: 18),
                      const Text('Belum ada tugas yang dicoba diselesaikan', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('Setelah Anda submit verifikasi, bukti percobaan penyelesaian tugas akan muncul di sini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final h = history.reversed.toList()[i];
                  return Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: .94),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (h.photoPath != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: Image.network(h.photoPath!, height: 180, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.fact_check, color: Colors.green)),
                          title: Text(h.taskTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text('Task ID: ${h.taskId}'),
                          trailing: const Chip(label: Text('SUDAH DICOBA')),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bukti bahwa user telah mencoba menyelesaikan tugas ini.', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('Lokasi bukti: ${h.latitude}, ${h.longitude}'),
                              Text('Dikirim: ${dateFormat.format(h.completedAt)}'),
                              Text('Durasi pengerjaan: ${h.completionDuration.inMinutes} menit'),
                              if (h.notes.trim().isNotEmpty) Text('Catatan: ${h.notes}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
