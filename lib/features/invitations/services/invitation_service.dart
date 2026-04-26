import '../../../core/network/api_client.dart';
import '../models/invitation_models.dart';

class InvitationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ProjectInvitation>> getMyPendingInvitations() async {
    final response = await _apiClient.dio.get('/project-invitations/me');

    final data = response.data as List;

    return data
        .map((item) => ProjectInvitation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptInvitation(String invitationId) async {
    await _apiClient.dio.post('/project-invitations/$invitationId/accept');
  }

  Future<void> rejectInvitation(String invitationId) async {
    await _apiClient.dio.post('/project-invitations/$invitationId/reject');
  }
}