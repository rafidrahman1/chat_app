import 'package:deadshot/components/google_sign_in_button.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //logo
            Icon(Icons.message, size: 60, color: colorScheme.tertiary),

            const SizedBox(height: 20),

            //google sign in button
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: GoogleSignInButton(),
            ),
          ],
        ),
      ),
    );
  }
}
