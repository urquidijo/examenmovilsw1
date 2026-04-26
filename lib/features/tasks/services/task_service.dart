import '../../../core/network/api_client.dart';
import '../models/task_models.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DepartmentTaskBoard>> getTaskBoardDepartments(
    String projectId,
  ) async {
    final response = await _apiClient.dio.get(
      '/projects/$projectId/task-board/departments',
    );

    final data = response.data as List;

    return data
        .map(
          (item) => DepartmentTaskBoard.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<WorkflowTask> getTaskDetail(String projectId, String taskId) async {
    final response = await _apiClient.dio.get(
      '/projects/$projectId/tasks/$taskId',
    );

    return WorkflowTask.fromJson(response.data);
  }

  Future<WorkflowTask> completeTask(
    String projectId,
    String taskId, {
    Map<String, dynamic>? tramiteData,
    String? decisionResult,
    List<MultipartFile> files = const [],
  }) async {
    final payload = {
      'tramiteData': tramiteData ?? {},
      if (decisionResult != null && decisionResult.isNotEmpty)
        'decisionResult': decisionResult,
    };

    final formData = FormData.fromMap({
      'payload': MultipartFile.fromString(
        jsonEncode(payload),
        contentType: DioMediaType('application', 'json'),
        filename: 'payload.json',
      ),
      'files': files,
    });

    final response = await _apiClient.dio.post(
      '/projects/$projectId/tasks/$taskId/complete',
      data: formData,
    );

    return WorkflowTask.fromJson(response.data);
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
