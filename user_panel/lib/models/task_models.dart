enum TaskStatus { pending, diproses, selesai }

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
  });
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
  });

  Duration get completionDuration => completedAt.difference(startedAt);
}