import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Listens for connectivity changes and fires [onConnected] callbacks.
/// Used by AppCubit to trigger silent background sync when the device
/// comes back online — the user never needs to tap "Sync Now".
class BackgroundSyncService {
  BackgroundSyncService._();
  static final BackgroundSyncService instance = BackgroundSyncService._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final List<AsyncCallback> _listeners = [];

  bool _wasOffline = false;

  /// Start listening. Call once from main() or AppCubit.
  void start() {
    _subscription?.cancel();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void addListener(AsyncCallback callback) {
    if (!_listeners.contains(callback)) _listeners.add(callback);
  }

  void removeListener(AsyncCallback callback) {
    _listeners.remove(callback);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline && _wasOffline) {
      // Just came back online — fire all listeners silently
      for (final cb in List.of(_listeners)) {
        cb().catchError((_) {}); // swallow errors — this is background
      }
    }
    _wasOffline = !isOnline;
  }

  /// Check current connectivity once (used at startup).
  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
