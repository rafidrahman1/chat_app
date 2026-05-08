import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_paths.dart';
import '../../model/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestorePaths.usersCollection);

  Stream<Map<String, UserProfile>> watchAllUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      final map = <String, UserProfile>{};
      for (final doc in snapshot.docs) {
        map[doc.id] = UserProfile.fromMap(doc.id, doc.data());
      }
      return map;
    });
  }

  Future<void> upsertUserProfile({
    required String uid,
    required String displayName,
    required String photoUrl,
    String? nickname,
    String? favoriteAgent,
    String? role,
  }) async {
    await _usersCollection.doc(uid).set({
      'displayName': displayName.trim(),
      'photoUrl': photoUrl.trim(),
      if (nickname != null) 'nickname': nickname.trim(),
      if (favoriteAgent != null) 'favoriteAgent': favoriteAgent.trim(),
      if (role != null) 'role': role.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    await _usersCollection.doc(uid).set({
      'isOnline': isOnline,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
