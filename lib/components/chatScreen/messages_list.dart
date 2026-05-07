import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import 'message_bubble.dart';

class MessagesList extends ConsumerStatefulWidget {
  const MessagesList({super.key});

  @override
  ConsumerState<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends ConsumerState<MessagesList> {
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
      _scrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
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
    final currentUser = ref.watch(authStateChangesProvider).asData?.value;
    final currentUserId = currentUser?.uid;
    final messagesState = ref.watch(chatMessagesProvider);
    final profiles = ref.watch(userProfilesProvider).asData?.value ?? const {};

    return messagesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(child: Text('Something went wrong loading messages.')),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(child: Text('No messages yet. Start the conversation!'));
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
                final senderProfile = profiles[message.senderId];
                final avatarUrl = isMe ? currentUser?.photoURL : senderProfile?.photoUrl;
                final fallbackLabel = isMe ? null : (senderProfile?.displayName.isNotEmpty == true ? senderProfile!.displayName : null);
                final senderName = isMe
                    ? ((currentUser?.displayName ?? '').trim().isNotEmpty ? (currentUser?.displayName ?? '').trim() : 'You')
                    : (senderProfile?.displayName.trim().isNotEmpty == true ? senderProfile!.displayName.trim() : null);
                final previousSender = index > 0 ? messages[index - 1].senderId : null;
                final nextSender = index < messages.length - 1 ? messages[index + 1].senderId : null;
                final startsGroup = previousSender != message.senderId;
                final endsGroup = nextSender != message.senderId;
                return MessageBubble(
                  message: message,
                  isMe: isMe,
                  startsGroup: startsGroup,
                  endsGroup: endsGroup,
                  senderName: senderName,
                  avatarUrl: avatarUrl,
                  fallbackLabel: fallbackLabel,
                );
              },
            ),
            if (!_isNearBottom)
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(onPressed: () => _scrollToBottom(), child: const Icon(Icons.keyboard_arrow_down)),
              ),
          ],
        );
      },
    );
  }
}
