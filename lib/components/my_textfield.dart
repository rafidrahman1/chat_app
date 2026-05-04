import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final String? hintText;
  final bool? obscureText;
  final TextEditingController? controller;
  const MyTextfield({super.key, required this.hintText, this.obscureText, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 6, 25, 6),
      child: TextField(
        obscureText: obscureText ?? false,
        controller: controller,
        style: TextStyle(color: Colors.white),

        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 3)),
          hintText: hintText,
          filled: true,
          fillColor: Colors.black,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      ),
    );
  }
}
