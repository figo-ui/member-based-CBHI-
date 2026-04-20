import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/data/facility_repository.dart';
import 'src/shared/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS notification tray automatically
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final repository = FacilityRepository();
  await repository.init();

  // Listen for foreground FCM messages — show in-app snackbar via overlay
  FcmService.instance.onForegroundMessage((message) {
    debugPrint('[FCM] Facility foreground: ${message.notification?.title}');
  });

  // Re-register token on refresh (handles token rotation)
  FcmService.instance.onTokenRefresh((newToken) async {
    try {
      await repository.registerFcmToken(newToken);
    } catch (_) {}
  });

  runApp(CbhiFacilityApp(repository: repository));
}
