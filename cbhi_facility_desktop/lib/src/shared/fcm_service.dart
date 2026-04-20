import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart'
    if (dart.library.html) 'fiam_stubs.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging (FCM) and In-App Messaging setup.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _fiam = FirebaseInAppMessaging.instance;

  /// Initialize FCM.
  Future<String?> init({String? vapidKey}) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Permission denied');
      return null;
    }

    String? token;
    try {
      if (kIsWeb && vapidKey != null) {
        token = await messaging.getToken(vapidKey: vapidKey);
      } else {
        token = await messaging.getToken();
      }
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _fiam.setMessagesSuppressed(false);
    return token;
  }

  void onTokenRefresh(Future<void> Function(String token) onRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen(onRefresh);
  }

  void onForegroundMessage(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  void onNotificationTap(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }
}
