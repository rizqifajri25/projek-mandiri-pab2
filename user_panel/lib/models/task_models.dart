import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, diproses, selesai }

TaskStatus taskStatusFromString(String? value) {
  return TaskStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => TaskStatus.pending,
  );
}

class FieldTask {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime startAt;
  final DateTime dueAt;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String assignedTo;
  final String? assignedToId;
  final String? assignedToEmail;
  final bool isGeneral;
  final int salaryBonus;

  const FieldTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startAt,
    required this.dueAt,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.assignedTo,
    this.assignedToId,
    this.assignedToEmail,
    this.isGeneral = false,
    this.salaryBonus = 0,
  });

  factory FieldTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime readDate(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    double readDouble(String key) {
      final value = data[key];
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return FieldTask(
      id: doc.id,
      title: data['title'] ?? 'Tanpa judul',
      description: data['description'] ?? '',
      status: taskStatusFromString(data['status']),
      startAt: readDate('startAt'),
      dueAt: readDate('dueAt'),
      latitude: readDouble('latitude'),
      longitude: readDouble('longitude'),
      imageUrl: data['imageUrl'] ?? '',
      assignedTo: data['assignedTo'] ?? 'Semua user',
      assignedToId: data['assignedToId'],
      assignedToEmail: data['assignedToEmail'],
      isGeneral: data['isGeneral'] == true,
      salaryBonus: (data['salaryBonus'] as num?)?.toInt() ?? 0,
    );
  }
}

class VerificationRecord {
  final String id;
  final String taskId;
  final String taskTitle;
  final DateTime startedAt;
  final DateTime completedAt;
  final String? photoPath;
  final double latitude;
  final double longitude;
  final String notes;
  final String state;

  const VerificationRecord({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.startedAt,
    required this.completedAt,
    this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.notes,
    this.state = 'menunggu',
  });

  factory VerificationRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime readDate(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    double readDouble(String key) {
      final value = data[key];
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return VerificationRecord(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      taskTitle: data['taskTitle'] ?? 'Tanpa judul',
      startedAt: readDate('startedAt'),
      completedAt: readDate('completedAt'),
      photoPath: data['photoPath'],
      latitude: readDouble('latitude'),
      longitude: readDouble('longitude'),
      notes: data['notes'] ?? '',
      state: data['state'] ?? 'menunggu',
    );
  }

  Duration get completionDuration => completedAt.difference(startedAt);
}
