import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_paths.dart';

class AuthService {
  //instance of the auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //get current user
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //Sign in with google
  Future<User?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
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
    final displayName = (user.displayName ?? '').trim();
    final photoUrl = (user.photoURL ?? '').trim();

    await _firestore.collection(FirestorePaths.usersCollection).doc(user.uid).set(
      {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> cacheCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _cacheUserProfile(user);
  }

  //sign out
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
