import 'package:flutter/material.dart';

import '../../model/message.dart';
import './avatar_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool startsGroup;
  final bool endsGroup;
  final String? avatarUrl;
  final String? fallbackLabel;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.startsGroup,
    required this.endsGroup,
    required this.avatarUrl,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messageColor = colorScheme.surface;
    final textColor = colorScheme.onSurface;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (endsGroup ? 4 : 18)),
      bottomRight: Radius.circular(isMe ? (endsGroup ? 4 : 18) : 18),
    );

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: EdgeInsets.only(top: startsGroup ? 8 : 2, bottom: endsGroup ? 8 : 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: messageColor,
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(message.content, style: TextStyle(fontSize: 15, color: textColor)),
    );

    if (isMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bubble,
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                if (endsGroup)
                  AvatarWidget(
                    avatarUrl: avatarUrl,
                    fallbackLabel: fallbackLabel,
                  )
                else
                  const SizedBox(width: 28),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              if (endsGroup)
                AvatarWidget(
                  avatarUrl: avatarUrl,
                  fallbackLabel: fallbackLabel,
                )
              else
                const SizedBox(width: 28),
            ],
          ),
        ),
        const SizedBox(width: 6),
        bubble,
      ],
    );
  }
}
