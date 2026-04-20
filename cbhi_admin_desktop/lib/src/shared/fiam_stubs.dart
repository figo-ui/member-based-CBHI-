/// Stub for Firebase In-App Messaging on Web/Desktop where it's not supported.
class FirebaseInAppMessaging {
  FirebaseInAppMessaging._();
  static final FirebaseInAppMessaging instance = FirebaseInAppMessaging._();

  Future<void> setMessagesSuppressed(bool suppressed) async {}
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}
  Future<void> triggerEvent(String eventName) async {}
}
