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
    final Timestamp timestamp = Timestamp.now();

    //create newMessage
    final newMessage = Message(
      msgId: timestamp.millisecondsSinceEpoch,
      content: message,
      timestamp: timestamp.toDate(),
      senderId: currentUserID,
    );

    // write message to Firestore under the single chat room
    await _messagesCollection.add(newMessage.toMap());
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

}
