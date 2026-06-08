import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(adminMessagesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi Admin')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade50, Colors.green.shade50, Colors.white],
          ),
        ),
        child: messages.isEmpty
            ? const Center(child: Text('Belum ada notifikasi'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Card(
                  elevation: 0,
                  color: Colors.white.withValues(alpha: .92),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(Icons.admin_panel_settings, color: Colors.teal),
                    ),
                    title: Text(messages[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Aktivitas admin terkait akun dan tugas Anda'),
                  ),
                ),
              ),
      ),
    );
  }
}
