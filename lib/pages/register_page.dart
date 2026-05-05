import 'package:flutter/material.dart';

import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../services/auth/auth_service.dart';

class RegisterScreen extends StatelessWidget {
  //email, password and confirm password text editing controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final void Function()? onTap;

  RegisterScreen({super.key, required this.onTap});

  //register method
  void register(BuildContext context) {
    final _auth = AuthService();

    //password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      try {
        _auth.createUserWithEmailAndPassword(_emailController.text, _passwordController.text);
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(title: Text('Error'), content: Text(e.toString())),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text('Error'), content: Text('Passwords do not match')),
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
            MyTextfield(hintText: 'Password', obscureText: true, controller: _passwordController),

            //confirm password textfield
            MyTextfield(hintText: 'Confirm Password', obscureText: true, controller: _confirmPasswordController),

            //register button
            MyButton(text: 'Register', onTap: () => register(context)),

            SizedBox(height: 20),

            //login now
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already a member?', style: TextStyle(color: colorScheme.onSurface)),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'Login now',
                    style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
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
