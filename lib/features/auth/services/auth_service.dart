import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/services/push_token_service.dart';
import '../models/auth_models.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();
  final PushTokenService _pushTokenService = PushTokenService();

  Future<void> login(LoginRequest data) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: data.toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);

    await _tokenStorage.saveToken(authResponse.token);
    await _tokenStorage.saveUser(authResponse.userToJson());

    await _pushTokenService.syncFcmToken();
  }

  Future<void> register(RegisterRequest data) async {
    await _apiClient.dio.post('/auth/register', data: data.toJson());
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
