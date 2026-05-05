import 'package:flutter/material.dart';

import '../components/my_button.dart';
import '../components/my_textfield.dart';

class RegisterScreen extends StatelessWidget {
  //email, password and confirm password text editing controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final void Function()? onTap;

  RegisterScreen({super.key, required this.onTap});

  //register method
  void register() {
    print('Register button tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //logo
            Icon(Icons.message, size: 60, color: Colors.grey),

            SizedBox(height: 20),

            //email textfield
            MyTextfield(hintText: 'Email', controller: _emailController),

            //password textfield
            MyTextfield(
              hintText: 'Password',
              obscureText: true,
              controller: _passwordController,
            ),

            //confirm password textfield
            MyTextfield(
              hintText: 'Confirm Password',
              obscureText: true,
              controller: _confirmPasswordController,
            ),

            //register button
            MyButton(text: 'Register', onTap: register),

            SizedBox(height: 20),

            //login now
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already a member?',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'Login now',
                    style: TextStyle(
                      color: Colors.redAccent,
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
