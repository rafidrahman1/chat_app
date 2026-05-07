import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  //handle google sign in
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleGoogleSignIn() async {
      try {
        await ref.read(authServiceProvider).signInWithGoogle();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google sign in failed: $e')));
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
          children: [
            Image.asset('assets/images/google_logo.png', height: 40),
            Text('Sign in with Google'),
          ],
        ),
      ),
    );
  }
}
