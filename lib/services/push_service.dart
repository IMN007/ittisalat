import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initiera push och be om tillåtelse
  Future<void> initPushNotifications(Function(RemoteMessage) onMessage) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// Hämta FCM-token
  Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  /// Lyssna på push vid bakgrund/start
  void handleInitialPush(Function(RemoteMessage) onMessageOpenedApp) {
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
  }
}
