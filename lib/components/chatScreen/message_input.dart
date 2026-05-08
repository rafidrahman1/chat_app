import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCreatePoll;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onCreatePoll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onCreatePoll,
              icon: const Icon(Icons.poll_outlined),
              tooltip: 'Create poll',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                cursorColor: colorScheme.onSurface,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Aa',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.onSurface),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.onSurface),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 25,
              backgroundColor: colorScheme.secondary,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onSend,
                icon: Icon(
                  Icons.send_rounded,
                  color: colorScheme.onSecondary,
                  size: 19,
                ),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
