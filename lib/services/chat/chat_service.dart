import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../model/message.dart';

class ChatService {
  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // single global chat room id used by all users
  static const String _globalChatRoomId = 'global_chat_room';
  // Insecure by design: personal-project fallback for sending FCM from client.
  static const String _fcmServerKey = String.fromEnvironment('FCM_SERVER_KEY');

  // helper to get messages collection reference for the global room
  CollectionReference<Map<String, dynamic>> get _messagesCollection {
    return _firestore
        .collection('chatRooms')
        .doc(_globalChatRoomId)
        .collection('messages');
  }

  String _normalizePhotoUrl(String? url) {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://')) {
      return trimmed.replaceFirst('http://', 'https://');
    }
    return trimmed;
  }

  String _resolveSenderPhotoUrl(User user) {
    final direct = _normalizePhotoUrl(user.photoURL);
    if (direct.isNotEmpty) return direct;

    for (final profile in user.providerData) {
      final providerUrl = _normalizePhotoUrl(profile.photoURL);
      if (providerUrl.isNotEmpty) return providerUrl;
    }

    return '';
  }

  //send message to the single global chat room. The receiverEmail parameter is ignored
  //to keep compatibility with existing callers.
  Future<void> sendMessage(String receiverEmail, String message) async {
    // ensure user is signed in
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'NO_CURRENT_USER',
        message: 'No authenticated user to send a message',
      );
    }

    final String currentUserID = user.uid;
    final String displayName = user.displayName ?? 'Anonymous';
    final String senderPhotoUrl = _resolveSenderPhotoUrl(user);
    final String senderEmail = user.email ?? '';
    final Timestamp timestamp = Timestamp.now();

    //create newMessage
    Message newMessage = Message(
      msgId: timestamp.millisecondsSinceEpoch,
      content: message,
      timestamp: timestamp.toDate(),
      senderId: currentUserID,
      displayName: displayName,
      senderPhotoUrl: senderPhotoUrl,
      senderEmail: senderEmail,
    );

    // write message to Firestore under the single chat room
    await _messagesCollection.add(newMessage.toMap());
    await _sendClientSidePush(newMessage);
  }

  // Stream of messages from the single global chat room, ordered by msgId (ascending)
  Stream<List<Message>> getChatMessagesStream() {
    return _messagesCollection
        .orderBy('msgId', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList(),
        );
  }

  Future<void> _sendClientSidePush(Message message) async {
    if (_fcmServerKey.trim().isEmpty) {
      debugPrint('FCM_SERVER_KEY is empty; skipping direct push send.');
      return;
    }

    final usersSnap = await _firestore.collection('users').get();
    final tokens = <String>{};
    final senderTokens = <String>{};

    for (final doc in usersSnap.docs) {
      final rawTokens = doc.data()['fcmTokens'];
      if (rawTokens is! List) continue;

      for (final raw in rawTokens) {
        final token = (raw ?? '').toString().trim();
        if (token.isEmpty) continue;
        if (doc.id == message.senderId) {
          senderTokens.add(token);
        } else {
          tokens.add(token);
        }
      }
    }

    // Solo testing fallback when only sender token exists.
    if (tokens.isEmpty && senderTokens.isNotEmpty) {
      tokens.addAll(senderTokens);
    }
    if (tokens.isEmpty) {
      debugPrint('No FCM tokens available for message push.');
      return;
    }

    final payload = {
      'registration_ids': tokens.toList(),
      'priority': 'high',
      'notification': {
        'title': 'New chat message',
        'body': message.content.isEmpty ? 'You received a new message' : message.content,
      },
      'data': {
        'senderId': message.senderId,
        'msgId': message.msgId.toString(),
        'title': 'New chat message',
        'body': message.content,
        'roomId': _globalChatRoomId,
      },
      'android': {
        'priority': 'high',
      },
    };

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_fcmServerKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 400) {
      debugPrint('Direct FCM send failed: ${response.statusCode} ${response.body}');
      return;
    }
    debugPrint('Direct FCM send OK: ${response.body}');
  }
}
