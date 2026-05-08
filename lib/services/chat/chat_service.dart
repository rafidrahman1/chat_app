import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firestore_paths.dart';
import '../../model/message.dart';

class ChatService {
  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // helper to get messages collection reference for the global room
  CollectionReference<Map<String, dynamic>> get _messagesCollection {
    return _firestore
        .collection(FirestorePaths.chatRoomsCollection)
        .doc(FirestorePaths.globalChatRoomId)
        .collection(FirestorePaths.messagesCollection);
  }

  Future<String> _requireCurrentUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'NO_CURRENT_USER',
        message: 'No authenticated user to send a message',
      );
    }
    return user.uid;
  }

  //send message to the single global chat room. The receiverEmail parameter is ignored
  //to keep compatibility with existing callers.
  Future<void> sendMessage(String receiverEmail, String message) async {
    await sendTextMessage(message);
  }

  Future<void> sendTextMessage(String message) async {
    final String currentUserID = await _requireCurrentUserId();
    final Timestamp timestamp = Timestamp.now();

    final newMessage = Message(
      docId: '',
      msgId: timestamp.millisecondsSinceEpoch,
      content: message,
      timestamp: timestamp.toDate(),
      senderId: currentUserID,
    );

    await _messagesCollection.add(newMessage.toMap());
  }

  Future<void> sendYesNoPoll(String question) async {
    final String currentUserID = await _requireCurrentUserId();
    final Timestamp timestamp = Timestamp.now();

    final pollMessage = Message(
      docId: '',
      msgId: timestamp.millisecondsSinceEpoch,
      content: '',
      timestamp: timestamp.toDate(),
      senderId: currentUserID,
      type: 'poll',
      pollQuestion: question.trim(),
      pollVotes: const {'yes': 0, 'no': 0},
    );

    await _messagesCollection.add(pollMessage.toMap());
  }

  Future<void> toggleReaction({
    required String messageDocId,
    required String emoji,
  }) async {
    final String currentUserID = await _requireCurrentUserId();
    final docRef = _messagesCollection.doc(messageDocId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final reactionsByUser =
          (data['reactionsByUser'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry('$k', '$v'),
          );
      final current = reactionsByUser[currentUserID];

      if (current == emoji) {
        reactionsByUser.remove(currentUserID);
      } else {
        reactionsByUser[currentUserID] = emoji;
      }

      transaction.set(docRef, {
        'reactionsByUser': reactionsByUser,
      }, SetOptions(merge: true));
    });
  }

  Future<void> voteYesNoPoll({
    required String messageDocId,
    required bool voteYes,
  }) async {
    final String currentUserID = await _requireCurrentUserId();
    final voteValue = voteYes ? 'yes' : 'no';
    final docRef = _messagesCollection.doc(messageDocId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final pollVotes =
          (data['pollVotes'] as Map<String, dynamic>? ?? {'yes': 0, 'no': 0})
              .map((k, v) => MapEntry('$k', (v as num?)?.toInt() ?? 0));
      final votesByUser =
          (data['pollVotesByUser'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry('$k', '$v'),
          );

      final previous = votesByUser[currentUserID];
      if (previous == voteValue) {
        return;
      }

      if (previous != null) {
        pollVotes[previous] = (pollVotes[previous] ?? 0) - 1;
      }

      votesByUser[currentUserID] = voteValue;
      pollVotes[voteValue] = (pollVotes[voteValue] ?? 0) + 1;
      pollVotes.updateAll((_, count) => count < 0 ? 0 : count);

      transaction.set(docRef, {
        'pollVotes': pollVotes,
        'pollVotesByUser': votesByUser,
      }, SetOptions(merge: true));
    });
  }

  Stream<List<Message>> getChatMessagesStream() {
    return _messagesCollection
        .orderBy('msgId', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }
}
