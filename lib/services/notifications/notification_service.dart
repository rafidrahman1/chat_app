import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../routes.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for incoming chat messages',
    importance: Importance.high,
  );

  bool _initialized = false;
  bool _localNotificationsInitialized = false;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications(navigatorKey);
    await _initializeFcmHandlers(navigatorKey);

    _auth.authStateChanges().listen((user) async {
      if (user == null) return;
      await _syncTokenForUser(user.uid);
    });
    _messaging.onTokenRefresh.listen((token) async {
      final user = _auth.currentUser;
      if (user == null || token.trim().isEmpty) return;
      await _saveToken(user.uid, token);
    });

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _syncTokenForUser(currentUser.uid);
    }
  }

  Future<void> _initializeLocalNotifications(GlobalKey<NavigatorState> navigatorKey) async {
    if (_localNotificationsInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {
        navigatorKey.currentState?.pushNamed(AppRoutes.chat);
      },
    );
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_chatChannel);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _localNotificationsInitialized = true;
  }

  Future<void> ensureBackgroundLocalNotificationsInitialized() async {
    if (_localNotificationsInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings: settings);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_chatChannel);
    _localNotificationsInitialized = true;
  }

  Future<void> _initializeFcmHandlers(GlobalKey<NavigatorState> navigatorKey) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      navigatorKey.currentState?.pushNamed(AppRoutes.chat);
    }

    FirebaseMessaging.onMessage.listen((message) async {
      await showForegroundRemoteMessage(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      navigatorKey.currentState?.pushNamed(AppRoutes.chat);
    });
  }

  Future<void> _syncTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _saveToken(uid, token);
  }

  Future<void> _saveToken(String uid, String token) async {
    debugPrint('FCM token synced for user $uid: ${token.substring(0, token.length > 12 ? 12 : token.length)}...');
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdatedAt': FieldValue.serverTimestamp(),
      'fcmPlatform': Platform.operatingSystem,
    }, SetOptions(merge: true));
  }

  Future<void> _showLocalNotification({required int msgId, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

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

  static Future<void> showForegroundRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final body = notification.body ?? message.data['body']?.toString() ?? 'You received a new message';
    final msgId = int.tryParse(message.messageId ?? '') ?? DateTime.now().millisecondsSinceEpoch;
    await instance.ensureBackgroundLocalNotificationsInitialized();
    await instance._showLocalNotification(msgId: msgId, body: body);
  }

  int _notificationIdFromMsgId(int msgId) {
    const maxAndroidNotificationId = 2147483647;
    final normalized = msgId.abs() % maxAndroidNotificationId;
    return normalized == 0 ? 1 : normalized;
  }
}
