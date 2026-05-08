import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firestore_paths.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  //get current user
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user != null) {
        await _cacheUserProfile(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception('FirebaseAuthException: ${e.message}');
    }
  }

  Future<void> _cacheUserProfile(User user) async {
    final photoUrl = (user.photoURL ?? '').trim();
    final docRef = _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(user.uid);
    final snapshot = await docRef.get();
    final existingDisplayName = '${snapshot.data()?['displayName'] ?? ''}'
        .trim();
    final displayName = existingDisplayName.isNotEmpty
        ? existingDisplayName
        : (user.displayName ?? '').trim();

    await docRef.set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cacheCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _cacheUserProfile(user);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
