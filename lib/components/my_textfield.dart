import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final String? hintText;
  final bool? obscureText;
  final TextEditingController? controller;
  const MyTextfield({super.key, required this.hintText, this.obscureText, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 6, 25, 6),
      child: TextField(
        obscureText: obscureText ?? false,
        controller: controller,
        style: TextStyle(color: colorScheme.tertiary),

        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.tertiary),
        ),
      ),
    );
  }
}
