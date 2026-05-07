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

class LastReadMsgIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void markRead(int msgId) => state = msgId;

  void clear() => state = null;
}

final lastReadMsgIdProvider =
    NotifierProvider<LastReadMsgIdNotifier, int?>(LastReadMsgIdNotifier.new);

final hasUnreadMessagesProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(authStateChangesProvider).asData?.value;
  final currentUserId = currentUser?.uid;
  if (currentUserId == null || currentUserId.isEmpty) return false;

  final messages = ref.watch(chatMessagesProvider).asData?.value;
  if (messages == null || messages.isEmpty) return false;

  final lastReadMsgId = ref.watch(lastReadMsgIdProvider);
  final latestIncoming = messages.lastWhere(
    (message) => message.senderId != currentUserId,
    orElse: () => Message(
      msgId: 0,
      content: '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      senderId: currentUserId,
    ),
  );

  if (latestIncoming.msgId == 0) return false;
  if (lastReadMsgId == null) return true;
  return latestIncoming.msgId > lastReadMsgId;
});
