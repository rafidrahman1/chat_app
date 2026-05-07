import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/message.dart';
import '../services/auth/auth_service.dart';
import '../services/chat/chat_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final chatMessagesProvider = StreamProvider<List<Message>>((ref) {
  return ref.watch(chatServiceProvider).getChatMessagesStream();
});
