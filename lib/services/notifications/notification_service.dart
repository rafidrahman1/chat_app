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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSubscription;
  int? _lastSeenMessageId;
  String? _listeningUserId;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications(navigatorKey);

    _auth.authStateChanges().listen((user) {
      _chatSubscription?.cancel();
      _lastSeenMessageId = null;
      _listeningUserId = user?.uid;

      if (user != null) {
        _listenForNewMessages(user.uid);
      }
    });

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _listeningUserId = currentUser.uid;
      _listenForNewMessages(currentUser.uid);
    }
  }

  Future<void> _initializeLocalNotifications(GlobalKey<NavigatorState> navigatorKey) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {
        navigatorKey.currentState?.pushNamed(AppRoutes.chat);
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_chatChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _listenForNewMessages(String currentUserId) {
    _chatSubscription = _firestore
        .collection('chatRooms')
        .doc('global_chat_room')
        .collection('messages')
        .orderBy('msgId', descending: false)
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isEmpty) return;

          final newestMsgId = _parseMsgId(snapshot.docs.last.data()['msgId']);
          if (_lastSeenMessageId == null) {
            _lastSeenMessageId = newestMsgId;
            return;
          }

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final msgId = _parseMsgId(data['msgId']);
            if (msgId <= (_lastSeenMessageId ?? 0)) continue;

            final senderId = (data['senderId'] ?? '').toString();
            if (senderId == currentUserId || senderId.isEmpty) continue;

            final content = (data['content'] ?? '').toString();
            await _showLocalNotification(msgId: msgId, body: content);
          }

          _lastSeenMessageId = newestMsgId;
        });
  }

  Future<void> _showLocalNotification({required int msgId, required String body}) async {
    if (_listeningUserId == null) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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

  int _parseMsgId(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  int _notificationIdFromMsgId(int msgId) {
    const maxAndroidNotificationId = 2147483647;
    final normalized = msgId.abs() % maxAndroidNotificationId;
    return normalized == 0 ? 1 : normalized;
  }
}
