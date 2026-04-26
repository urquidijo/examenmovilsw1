import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';

class PushTokenService {
  final ApiClient _apiClient = ApiClient();

  Future<void> syncFcmToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken == null || fcmToken.isEmpty) return;

    await _apiClient.dio.post(
      '/users/fcm-token',
      data: {
        'fcmToken': fcmToken,
      },
    );
  }
}