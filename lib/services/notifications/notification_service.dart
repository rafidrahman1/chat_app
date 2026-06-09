import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/firestore_paths.dart';
import '../../routes.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Notifications for incoming chat messages',
        importance: Importance.high,
      );

  bool _initialized = false;
  bool _localNotificationsInitialized = false;
  StreamSubscription<User?>? _authStateSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications(navigatorKey);
    await _initializeMessaging(navigatorKey);

    _authStateSub = _auth.authStateChanges().listen((user) async {
      if (user == null) return;
      await _syncFcmTokenForCurrentUser();
    });
  }

  Future<void> _initializeLocalNotifications(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (_localNotificationsInitialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Deadshot',
      // Unique app identity used by Windows notification activation.
      // (This value should stay stable for the lifetime of your app.)
      appUserModelId: 'com.deadshot.chat_app',
      guid: '6b7f1e3c-6e44-4f2c-8c2d-9bb5e1d3c1d2',
    );
    const settings = InitializationSettings(
      android: androidSettings,
      windows: windowsSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {
        navigatorKey.currentState?.pushNamed(AppRoutes.chat);
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_chatChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _localNotificationsInitialized = true;
  }

  Future<void> _initializeMessaging(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      provisional: false,
    );

    // Ensure we have a token and persist it on the user profile.
    await _syncFcmTokenForCurrentUser();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      await _persistFcmToken(token);
    });

    // Foreground messages need manual display via local notifications.
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      final msgId = int.tryParse(
        message.data['msgId']?.toString() ??
            '${DateTime.now().millisecondsSinceEpoch}',
      );
      final body =
          message.notification?.body ??
          message.data['body']?.toString() ??
          'You received a new message';
      await _showLocalNotification(
        msgId: msgId ?? DateTime.now().millisecondsSinceEpoch,
        body: body,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      navigatorKey.currentState?.pushNamed(AppRoutes.chat);
    });
  }

  Future<void> _syncFcmTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    await _persistFcmToken(token);
  }

  Future<void> _persistFcmToken(String? token) async {
    final currentUser = _auth.currentUser;
    final normalized = token?.trim() ?? '';
    if (currentUser == null || normalized.isEmpty) return;

    await _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(currentUser.uid)
        .set({
          'fcmTokens': FieldValue.arrayUnion([normalized]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _showLocalNotification({
    required int msgId,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    // Windows toasts require Windows-specific notification details.
    const windowsDetails = WindowsNotificationDetails(
      duration: WindowsNotificationDuration.short,
      scenario: WindowsNotificationScenario.urgent,
      subtitle: 'New chat message',
    );

    const details = NotificationDetails(
      android: androidDetails,
      windows: windowsDetails,
    );

    try {
      await _localNotifications.show(
        id: _notificationIdFromMsgId(msgId),
        title: 'New chat message',
        body: body.isEmpty ? 'You received a new message' : body,
        notificationDetails: details,
      );
    } catch (error) {
      debugPrint('Failed to show local notification: $error');
    }
  }

  int _notificationIdFromMsgId(int msgId) {
    const maxAndroidNotificationId = 2147483647;
    final normalized = msgId.abs() % maxAndroidNotificationId;
    return normalized == 0 ? 1 : normalized;
  }
}
