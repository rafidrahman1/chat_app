import 'package:deadshot/auth/auth_service.dart';
import 'package:deadshot/components/my_button.dart';
import 'package:deadshot/components/my_textfield.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  //email and password text editing controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final void Function()? onTap;

  LoginScreen({super.key, required this.onTap});

  //login method
  void login(BuildContext context) {
    //auth service
    final authService = AuthService();

    //try login
    try {
      authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(title: Text('Error'), content: Text(e.toString())),
      );
    }
  }

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

            SizedBox(height: 20),

            //email textfield
            MyTextfield(hintText: 'Email', controller: _emailController),

            //password textfield
            MyTextfield(
              hintText: 'Password',
              obscureText: true,
              controller: _passwordController,
            ),

            //login button
            MyButton(text: 'Login', onTap: () => login(context)),

            SizedBox(height: 20),

            //register now
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not a member?',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'Register now',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
