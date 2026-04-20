import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'src/app.dart';
import 'src/data/facility_repository.dart';
import 'src/shared/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  final repository = FacilityRepository();
  await repository.init();
  
  // Setup FCM listeners
  FcmService.instance.onForegroundMessage((message) {
    debugPrint('[FCM] Facility Foreground: ${message.notification?.title}');
  });
  
  runApp(CbhiFacilityApp(repository: repository));
}
