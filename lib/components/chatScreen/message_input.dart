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
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0084FF)),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Aa',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  suffixIcon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0084FF),
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
