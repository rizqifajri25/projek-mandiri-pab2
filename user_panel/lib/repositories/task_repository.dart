import '../models/task_models.dart';
import '../services/firebase_backend_service.dart';

class TaskRepository {
  TaskRepository(this._backend);
  final FirebaseBackendService _backend;

  Future<List<FieldTask>> getTasks() => _backend.fetchTasks();
  Stream<List<FieldTask>> watchTasks() => _backend.streamTasks();
}
