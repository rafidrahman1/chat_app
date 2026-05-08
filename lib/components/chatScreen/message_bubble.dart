import 'package:flutter/material.dart';

import '../../model/message.dart';
import './avatar_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool startsGroup;
  final bool endsGroup;
  final String? senderName;
  final String? avatarUrl;
  final String? fallbackLabel;
  final String? currentUserId;
  final VoidCallback onAvatarTap;
  final ValueChanged<String> onReactionTap;
  final ValueChanged<bool> onPollVote;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.startsGroup,
    required this.endsGroup,
    required this.senderName,
    required this.avatarUrl,
    required this.fallbackLabel,
    required this.currentUserId,
    required this.onAvatarTap,
    required this.onReactionTap,
    required this.onPollVote,
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

    final header = startsGroup && (senderName ?? '').trim().isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(right: 10, left: 10),
            child: Text(
              senderName!,
              textAlign: isMe ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w200,
                color: colorScheme.onSurface,
              ),
            ),
          )
        : const SizedBox.shrink();

    final bubble = GestureDetector(
      onLongPressStart: (details) async {
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final position = RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          overlay.size.width - details.globalPosition.dx,
          overlay.size.height - details.globalPosition.dy,
        );

        final emoji = await showMenu<String>(
          context: context,
          position: position,
          items: const [
            PopupMenuItem(value: '👍', child: Text('👍 Like')),
            PopupMenuItem(value: '😂', child: Text('😂 Funny')),
            PopupMenuItem(value: '🔥', child: Text('🔥 Fire')),
            PopupMenuItem(value: '🎯', child: Text('🎯 Nice')),
          ],
        );

        if (emoji != null) {
          onReactionTap(emoji);
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: EdgeInsets.only(
          top: startsGroup ? 2 : 2,
          bottom: endsGroup ? 6 : 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: messageColor,
          borderRadius: radius,
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: _buildBubbleBody(context, textColor),
      ),
    );

    final messageColumn = Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        bubble,
        _ReactionRow(
          reactionsByUser: message.reactionsByUser,
          onTap: onReactionTap,
        ),
      ],
    );

    if (isMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          messageColumn,
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                if (endsGroup)
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: AvatarWidget(
                      avatarUrl: avatarUrl,
                      fallbackLabel: fallbackLabel,
                    ),
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
                GestureDetector(
                  onTap: onAvatarTap,
                  child: AvatarWidget(
                    avatarUrl: avatarUrl,
                    fallbackLabel: fallbackLabel,
                  ),
                )
              else
                const SizedBox(width: 28),
            ],
          ),
        ),
        const SizedBox(width: 6),
        messageColumn,
      ],
    );
  }

  Widget _buildBubbleBody(BuildContext context, Color textColor) {
    if (message.type != 'poll') {
      return Text(
        message.content,
        style: TextStyle(fontSize: 15, color: textColor),
      );
    }

    final yesVotes = message.pollVotes['yes'] ?? 0;
    final noVotes = message.pollVotes['no'] ?? 0;
    final myVote = currentUserId == null
        ? ''
        : (message.pollVotesByUser[currentUserId] ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (message.pollQuestion ?? '').isNotEmpty
              ? message.pollQuestion!
              : 'Yes/No Poll',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onPollVote(true),
                child: Text(
                  'Yes ($yesVotes)',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onPollVote(false),
                child: Text(
                  'No ($noVotes)',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        if (myVote.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            'You voted: $myVote',
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReactionRow extends StatelessWidget {
  final Map<String, String> reactionsByUser;
  final ValueChanged<String> onTap;

  const _ReactionRow({required this.reactionsByUser, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final emoji in reactionsByUser.values) {
      if (emoji.trim().isEmpty) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
      child: Wrap(
        spacing: 6,
        children: [
          ...counts.entries.map((entry) {
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onTap(entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text('${entry.key} ${entry.value}'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
