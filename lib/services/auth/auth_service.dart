import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  //instance of the auth & firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAuth _firestore = FirebaseAuth.instance;
  //Sign in
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //sign up
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      return userCredential;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //sign out

  Future<void> signOut() async {
    await _auth.signOut();
  }

  //errors
}
