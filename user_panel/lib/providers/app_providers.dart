import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_models.dart';
import '../repositories/task_repository.dart';
import '../services/firebase_backend_service.dart';

class UserProfile {
  final String name;
  final String email;
  final String? photoPath;

  UserProfile({
    required this.name,
    required this.email,
    this.photoPath,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoPath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

final firebaseBackendProvider = Provider((ref) => FirebaseBackendService());

final userProfileProvider = StateProvider<UserProfile>((ref) {
  final email =
      ref.watch(firebaseBackendProvider).currentUser?.email ?? 'user@gmail.com';
  final username = email.split('@').first;

  return UserProfile(name: username, email: email, photoPath: null);
});

final taskRepositoryProvider =
    Provider((ref) => TaskRepository(ref.read(firebaseBackendProvider)));

final authTokenProvider = StateProvider<String?>((ref) => null);
final darkModeProvider = StateProvider<bool>((ref) => false);
final taskStatusFilterProvider = StateProvider<TaskStatus?>((ref) => null);

final verificationHistoryProvider = StreamProvider<List<VerificationRecord>>(
  (ref) => ref.watch(firebaseBackendProvider).streamVerificationHistory(),
);

final adminMessagesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(firebaseBackendProvider).streamAdminMessages(),
);

final taskListProvider = StreamProvider<List<FieldTask>>((ref) {
  return ref.read(taskRepositoryProvider).watchTasks();
});
