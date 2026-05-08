import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/message.dart';
import '../../model/user_profile.dart';
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
    final currentUser = ref.watch(authStateChangesProvider).asData?.value;
    final currentUserId = currentUser?.uid;
    final messagesState = ref.watch(chatMessagesProvider);
    final profiles = ref.watch(userProfilesProvider).asData?.value ?? const {};
    final currentUserProfileName = currentUserId == null
        ? ''
        : profiles[currentUserId]?.displayName.trim() ?? '';
    final currentUserAuthName = (currentUser?.displayName ?? '').trim();
    final currentUserName = currentUserProfileName.isNotEmpty
        ? currentUserProfileName
        : (currentUserAuthName.isNotEmpty ? currentUserAuthName : 'You');

    return messagesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('Something went wrong loading messages.')),
      data: (messages) {
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

        return Column(
          children: [
            _OnlineNowStrip(currentUserId: currentUserId, profiles: profiles),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      final senderProfile = profiles[message.senderId];
                      final avatarUrl = isMe
                          ? currentUser?.photoURL
                          : senderProfile?.photoUrl;
                      final fallbackLabel = isMe
                          ? null
                          : (senderProfile?.displayName.isNotEmpty == true
                                ? senderProfile!.displayName
                                : null);
                      final senderName = isMe
                          ? currentUserName
                          : (senderProfile?.displayName.trim().isNotEmpty ==
                                    true
                                ? senderProfile!.displayName.trim()
                                : null);
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
                        senderName: senderName,
                        avatarUrl: avatarUrl,
                        fallbackLabel: fallbackLabel,
                        currentUserId: currentUserId,
                        onAvatarTap: () =>
                            _showProfileCard(context, senderProfile),
                        onReactionTap: (emoji) =>
                            _toggleReaction(message.docId, emoji),
                        onPollVote: (voteYes) =>
                            _voteOnPoll(message.docId, voteYes),
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
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleReaction(String docId, String emoji) async {
    try {
      await ref
          .read(chatServiceProvider)
          .toggleReaction(messageDocId: docId, emoji: emoji);
    } catch (_) {}
  }

  Future<void> _voteOnPoll(String docId, bool voteYes) async {
    try {
      await ref
          .read(chatServiceProvider)
          .voteYesNoPoll(messageDocId: docId, voteYes: voteYes);
    } catch (_) {}
  }

  Future<void> _showProfileCard(
    BuildContext context,
    UserProfile? profile,
  ) async {
    if (profile == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final nickname = profile.nickname.isNotEmpty
            ? profile.nickname
            : profile.displayName;
        final favoriteAgent = profile.favoriteAgent.isNotEmpty
            ? profile.favoriteAgent
            : 'Not set';
        final role = profile.role.isNotEmpty ? profile.role : 'Not set';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickname.isNotEmpty ? nickname : 'Unknown player',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Nickname: ${nickname.isNotEmpty ? nickname : 'Not set'}'),
              const SizedBox(height: 4),
              Text('Favorite agent: $favoriteAgent'),
              const SizedBox(height: 4),
              Text('Role: $role'),
            ],
          ),
        );
      },
    );
  }
}

class _OnlineNowStrip extends StatelessWidget {
  final String? currentUserId;
  final Map<String, UserProfile> profiles;

  const _OnlineNowStrip({required this.currentUserId, required this.profiles});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final online = profiles.values.where((profile) {
      if (profile.uid == currentUserId) return false;
      if (profile.isOnline) return true;
      final lastSeen = profile.lastSeenAt;
      if (lastSeen == null) return false;
      return now.difference(lastSeen).inMinutes <= 2;
    }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (online.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        itemBuilder: (_, index) {
          final profile = online[index];
          final label = profile.nickname.isNotEmpty
              ? profile.nickname
              : profile.displayName;
          return Chip(
            avatar: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.green,
            ),
            label: Text(label.isNotEmpty ? label : 'Player'),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: online.length,
      ),
    );
  }
}
