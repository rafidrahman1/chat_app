import 'package:flutter/material.dart';

import '../../model/message.dart';
import './avatar_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool startsGroup;
  final bool endsGroup;
  final String? myPhotoUrl;
  final String peerAvatarUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.startsGroup,
    required this.endsGroup,
    required this.myPhotoUrl,
    required this.peerAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    const messageColor = Colors.black;
    const textColor = Colors.white;
    final avatarUrl = isMe ? myPhotoUrl : peerAvatarUrl;
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
        border: Border.all(color: const Color(0xFFD3D3D3), width: 1),
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(children: [if (endsGroup) AvatarWidget(avatarUrl: avatarUrl) else const SizedBox(width: 28)]),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (endsGroup) AvatarWidget(avatarUrl: avatarUrl) else const SizedBox(width: 28),
        const SizedBox(width: 6),
        bubble,
      ],
    );
  }
}
