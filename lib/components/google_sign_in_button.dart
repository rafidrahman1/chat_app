import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  //handle google sign in
  Widget build(BuildContext context) {
    Future<void> handleGoogleSignIn() async {
      try {
        await AuthService().signInWithGoogle();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign in failed: $e')));
      }
    }

    return ElevatedButton(
      onPressed: handleGoogleSignIn,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 15,
          children: [Image.asset('assets/images/google_logo.png', height: 40), Text('Sign in with Google')],
        ),
      ),
    );
  }
}
