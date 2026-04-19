import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging setup and token registration.
/// Call [init] once after the user authenticates.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  /// Initialize FCM, request permission, and return the device token.
  /// Returns null if permission denied or on web (where FCM requires VAPID).
  Future<String?> init() async {
    if (kIsWeb) return null; // Web FCM requires separate VAPID setup

    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS/macOS prompt; Android 13+ prompt)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    // Get the FCM registration token
    final token = await messaging.getToken();

    // Configure foreground notification presentation (iOS)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    return token;
  }

  /// Listen for token refreshes and re-register with the backend
  void onTokenRefresh(Future<void> Function(String token) onRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen(onRefresh);
  }

  /// Handle foreground messages (show in-app banner)
  void onForegroundMessage(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  /// Handle notification tap when app is in background/terminated
  void onNotificationTap(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }
}
