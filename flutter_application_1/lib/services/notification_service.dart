import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? 'แจ้งเตือนจากร้าน';
        final body = message.notification?.body ?? '';
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
        );
      });
    } catch (error) {
      debugPrint('Push initialization failed: $error');
    }
  }

  static Future<void> registerCurrentDevice() async {
    try {
      if (!await ApiService.getNotificationPreference()) return;
    } catch (error) {
      debugPrint('Notification preference could not be loaded: $error');
      return;
    }
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final platform = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'other'));
      await ApiService.registerPushDevice(
        token,
        platform,
      );
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        ApiService.registerPushDevice(
          newToken,
          platform,
        );
      });
    } catch (error) {
      debugPrint('Push token registration failed: $error');
    }
  }
}
