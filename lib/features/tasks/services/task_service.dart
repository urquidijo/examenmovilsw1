import '../../../core/network/api_client.dart';
import '../models/task_models.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DepartmentTaskBoard>> getTaskBoardDepartments(String projectId) async {
    final response = await _apiClient.dio.get(
      '/projects/$projectId/task-board/departments',
    );

    final data = response.data as List;

    return data
        .map((item) => DepartmentTaskBoard.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkflowTask>> getMyDepartmentTasks(
    String projectId,
    String departmentId,
  ) async {
    final response = await _apiClient.dio.get(
      '/projects/$projectId/departments/$departmentId/my-tasks',
    );

    final data = response.data as List;

    return data
        .map((item) => WorkflowTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}