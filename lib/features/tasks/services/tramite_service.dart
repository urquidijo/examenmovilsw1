import '../../../core/network/api_client.dart';
import '../models/tramite_models.dart';

class TramiteService {
  final ApiClient _apiClient = ApiClient();

  Future<TramiteTemplate> getTramiteById(
    String projectId,
    String tramiteId,
  ) async {
    final response = await _apiClient.dio.get(
      '/projects/$projectId/tramites/$tramiteId',
    );

    return TramiteTemplate.fromJson(response.data);
  }
}