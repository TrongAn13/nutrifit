import 'package:firebase_messaging/firebase_messaging.dart';

/// Centralized service for Firebase Cloud Messaging operations.
///
/// Handles token retrieval, notification permission requests,
/// and foreground message listening.
class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  // ───────────────────────── Token ─────────────────────────

  /// Returns the current FCM device token, or null on failure.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      // FCM may not be available on all platforms (e.g. emulator).
      return null;
    }
  }

  /// Listens for token refresh events.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // ───────────────────────── Permissions ─────────────────────────

  /// Requests notification permission from the trainee.
  ///
  /// Returns the current [NotificationSettings] after the request.
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    return settings;
  }

  /// Returns the current permission status without prompting.
  Future<NotificationSettings> getPermissionStatus() async {
    return await _messaging.getNotificationSettings();
  }

  // ───────────────────────── Foreground Messages ─────────────────────────

  /// Sets up a foreground message listener.
  ///
  /// Call this once during app initialization.
  void configureForegroundHandler({
    required void Function(RemoteMessage message) onMessage,
  }) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// Sets up handler for when trainee taps a notification (app in background).
  void configureBackgroundTapHandler({
    required void Function(RemoteMessage message) onMessageOpenedApp,
  }) {
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
  }
}
