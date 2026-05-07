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
  }) async {
    await _usersCollection.doc(uid).set(
      {
        'displayName': displayName.trim(),
        'photoUrl': photoUrl.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

