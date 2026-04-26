import '../../../core/network/api_client.dart';
import '../models/project_models.dart';

class ProjectService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ProjectSummary>> getMyProjects() async {
    final response = await _apiClient.dio.get('/projects/me');

    final data = response.data as List;

    return data
        .map((item) => ProjectSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}