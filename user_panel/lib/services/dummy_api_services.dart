import '../models/task_models.dart';

class DummyApiService {
  Future<List<FieldTask>> fetchTasks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      FieldTask(
        id: 'T-001',
        title: 'Audit Site Jakarta Barat',
        description: 'Validasi panel utama dan dokumentasi kondisi aktual.',
        status: TaskStatus.pending,
        startAt: now.subtract(const Duration(hours: 2)),
        dueAt: now.add(const Duration(hours: 5)),
        latitude: -6.1944,
        longitude: 106.8229,
        imageUrl:
            'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800',
        assignedTo: 'petugas1',
      ),
      FieldTask(
        id: 'T-002',
        title: 'Inspeksi Gudang Tangerang',
        description: 'Cek keamanan area dan kepatuhan SOP.',
        status: TaskStatus.diproses,
        startAt: now.subtract(const Duration(hours: 1)),
        dueAt: now.add(const Duration(hours: 7)),
        latitude: -6.1783,
        longitude: 106.6319,
        imageUrl:
            'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800',
        assignedTo: 'petugas1',
      ),
    ];
  }
}