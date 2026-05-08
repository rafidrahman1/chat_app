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
      return await _authenticateWithGoogle(allowReauthRetry: true);
    } on GoogleSignInException catch (e) {
      final isAccountReauthFailure =
          e.description?.toLowerCase().contains('account reauth failed') ??
          false;
      final isCanceled = e.code == GoogleSignInExceptionCode.canceled;
      if (isCanceled && !isAccountReauthFailure) return null;
      throw Exception('GoogleSignInException: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw Exception(
        'FirebaseAuthException(${e.code}): ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      throw Exception('Unexpected sign-in error: $e');
    }
  }

  Future<User?> _authenticateWithGoogle({required bool allowReauthRetry}) async {
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _cacheUserProfile(user);
      }
      return user;
    } on GoogleSignInException catch (e) {
      final isAccountReauthFailure =
          e.description?.toLowerCase().contains('account reauth failed') ??
          false;
      if (allowReauthRetry && isAccountReauthFailure) {
        // Clear stale Google session state, then retry the flow once.
        await GoogleSignIn.instance.signOut();
        return _authenticateWithGoogle(allowReauthRetry: false);
      }
      rethrow;
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
