import 'package:flutter/material.dart';

import '../../model/message.dart';
import '../../services/auth/auth_service.dart';
import '../../services/chat/chat_service.dart';
import 'message_bubble.dart';

class MessagesList extends StatefulWidget {
  final ChatService chatService;
  final AuthService authService;

  const MessagesList({
    super.key,
    required this.chatService,
    required this.authService,
  });

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  final ScrollController _scrollController = ScrollController();
  static const double _autoScrollThreshold = 120;
  int _lastMessageCount = 0;
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final nearBottom = (max - current) <= _autoScrollThreshold;

    if (nearBottom != _isNearBottom && mounted) {
      setState(() {
        _isNearBottom = nearBottom;
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;

    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.authService.currentUser?.uid;

    return StreamBuilder<List<Message>>(
      stream: widget.chatService.getChatMessagesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong loading messages.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet. Start the conversation!'),
          );
        }

        final hasNewMessage = messages.length > _lastMessageCount;
        _lastMessageCount = messages.length;

        if (hasNewMessage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_isNearBottom) {
              _scrollToBottom();
            }
          });
        }

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message.senderId == currentUserId;
                final previousSender = index > 0
                    ? messages[index - 1].senderId
                    : null;
                final nextSender = index < messages.length - 1
                    ? messages[index + 1].senderId
                    : null;
                final startsGroup = previousSender != message.senderId;
                final endsGroup = nextSender != message.senderId;
                return MessageBubble(
                  message: message,
                  isMe: isMe,
                  startsGroup: startsGroup,
                  endsGroup: endsGroup,
                  myPhotoUrl: widget.authService.currentUser?.photoURL,
                );
              },
            ),
            if (!_isNearBottom)
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  onPressed: () => _scrollToBottom(),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
          ],
        );
      },
    );
  }
}
