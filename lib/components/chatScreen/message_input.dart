import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({super.key, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                cursorColor: Colors.white,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Aa',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.redAccent,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
