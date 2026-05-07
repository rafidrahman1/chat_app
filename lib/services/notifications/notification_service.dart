import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../routes.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for incoming chat messages',
    importance: Importance.high,
  );

  bool _initialized = false;
  bool _localNotificationsInitialized = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSubscription;
  int? _lastObservedMsgId;
  bool _isAppResumed = true;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(_LifecycleObserver(instance));
    await _initializeLocalNotifications(navigatorKey);
    _auth.authStateChanges().listen((_) => _startChatListener());
    _startChatListener();
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

  void _startChatListener() {
    _chatSubscription?.cancel();
    _lastObservedMsgId = null;

    _chatSubscription = _firestore
        .collection('chatRooms')
        .doc('global_chat_room')
        .collection('messages')
        .orderBy('msgId', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isEmpty) return;

          final data = snapshot.docs.first.data();
          final msgId = int.tryParse('${data['msgId']}');
          if (msgId == null) return;

          // Prime state on first snapshot to avoid notifying for older messages.
          if (_lastObservedMsgId == null) {
            _lastObservedMsgId = msgId;
            return;
          }
          if (msgId <= _lastObservedMsgId!) return;
          _lastObservedMsgId = msgId;

          final senderId = '${data['senderId'] ?? ''}';
          final currentUserId = _auth.currentUser?.uid ?? '';
          if (senderId.isNotEmpty && senderId == currentUserId) return;

          final body = '${data['content'] ?? ''}';
          // User requested no notifications while inside the app.
          if (_isAppResumed) return;
          await _showLocalNotification(msgId: msgId, body: body);
        });
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

  int _notificationIdFromMsgId(int msgId) {
    const maxAndroidNotificationId = 2147483647;
    final normalized = msgId.abs() % maxAndroidNotificationId;
    return normalized == 0 ? 1 : normalized;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this._service);
  final NotificationService _service;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _service._isAppResumed = state == AppLifecycleState.resumed;
  }
}
