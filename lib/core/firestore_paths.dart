/// Central place for Firestore collection/document names used in the app.
///
/// Keeping these in one place prevents drift (e.g. `global_chat_room` being
/// duplicated in multiple services).
class FirestorePaths {
  FirestorePaths._();

  static const String chatRoomsCollection = 'chatRooms';
  static const String globalChatRoomId = 'global_chat_room';
  static const String messagesCollection = 'messages';
}

