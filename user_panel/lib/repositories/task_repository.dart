import '../models/task_models.dart';
import '../services/dummy_api_services.dart';

class TaskRepository {
  TaskRepository(this._api);
  final DummyApiService _api;

  Future<List<FieldTask>> getTasks() => _api.fetchTasks();
}