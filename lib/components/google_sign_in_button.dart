import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  //handle google sign in
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> handleGoogleSignIn() async {
      try {
        final user = await ref.read(authServiceProvider).signInWithGoogle();
        if (user == null) return;
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google sign in failed: $e')));
      }
    }

    return ElevatedButton(
      onPressed: handleGoogleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
        foregroundColor: colorScheme.onSurface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google_logo.png', height: 40),
            const SizedBox(width: 15),
            const Text('Sign in with Google'),
          ],
        ),
      ),
    );
  }
}
