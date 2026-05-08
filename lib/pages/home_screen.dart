import 'package:cached_network_image/cached_network_image.dart';
import 'package:deadshot/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/valorant_stack_state.dart';
import '../providers/app_providers.dart';
import '../routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final profiles = ref.watch(userProfilesProvider).asData?.value ?? const {};
    final hasUnreadMessages = ref.watch(hasUnreadMessagesProvider);
    final lastReadMsgId = ref.watch(lastReadMsgIdProvider);
    final stackStateAsync = ref.watch(valorantStackStateProvider);
    final stackState =
        stackStateAsync.asData?.value ?? ValorantStackState.empty('');

    ref.listen(chatMessagesProvider, (_, next) {
      final messages = next.asData?.value;
      if (messages == null || messages.isEmpty) return;
      if (ref.read(lastReadMsgIdProvider) != null) return;
      ref.read(lastReadMsgIdProvider.notifier).markRead(messages.last.msgId);
    });

    final avatar = user?.photoURL != null
        ? CircleAvatar(
            radius: 16,
            backgroundImage: CachedNetworkImageProvider(user!.photoURL!),
          )
        : const CircleAvatar(radius: 16, child: Icon(Icons.person));

    final profileName = user == null
        ? ''
        : profiles[user.uid]?.displayName.trim() ?? '';
    final authName = (user?.displayName ?? '').trim();
    final displayName = profileName.isNotEmpty
        ? profileName
        : (authName.isNotEmpty ? authName : 'Home');
    final currentUserName = profileName.isNotEmpty
        ? profileName
        : (authName.isNotEmpty
              ? authName
              : (user?.email?.trim() ?? 'Unknown player'));
    final hasJoinedStack = user != null && stackState.containsUser(user.uid);
    final canJoinStack = user != null && !stackState.isFull && !hasJoinedStack;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: 10),
            avatar,
          ],
        ),
      ),
      drawer: const MyDrawer(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StackActionCard(
              state: stackState,
              hasJoinedStack: hasJoinedStack,
              canJoinStack: canJoinStack,
              onJoinPressed: () async {
                await _handleJoinStack(
                  context: context,
                  ref: ref,
                  state: stackState,
                  currentUserName: currentUserName,
                );
              },
              onShowMembersPressed: () =>
                  _showStackMembers(context, stackState),
            ),
            const SizedBox(height: 16),
            _ChatActionButton(
              hasUnreadMessages: hasUnreadMessages,
              onPressed: () {
                if (lastReadMsgId == null) {
                  final messages = ref.read(chatMessagesProvider).asData?.value;
                  if (messages != null && messages.isNotEmpty) {
                    ref
                        .read(lastReadMsgIdProvider.notifier)
                        .markRead(messages.last.msgId);
                  }
                }
                Navigator.pushNamed(context, AppRoutes.chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoinStack({
    required BuildContext context,
    required WidgetRef ref,
    required ValorantStackState state,
    required String currentUserName,
  }) async {
    final currentUserUid = ref
        .read(authStateChangesProvider)
        .asData
        ?.value
        ?.uid;
    if (currentUserUid == null) return;

    final confirmed = await _confirmJoinStack(context, state);
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(valorantStackServiceProvider)
        .joinStack(uid: currentUserUid, displayName: currentUserName);
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_messageForJoinResult(result))));
  }

  String _messageForJoinResult(ValorantStackJoinResult result) {
    switch (result) {
      case ValorantStackJoinResult.joined:
        return 'You were added to today\'s Valorant 5 stack.';
      case ValorantStackJoinResult.alreadyJoined:
        return 'You already pushed it today.';
      case ValorantStackJoinResult.full:
        return 'Today\'s 5 stack is already full.';
      case ValorantStackJoinResult.unauthenticated:
        return 'Please sign in to join the 5 stack.';
    }
  }

  Future<bool> _confirmJoinStack(
    BuildContext context,
    ValorantStackState state,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Join today\'s Valorant 5 stack?'),
          content: Text(
            state.isFull
                ? 'This stack is already full. '
                      'You will not be able to join today.'
                : 'Confirm that you want to push the 5-stack button for today. '
                      'This will count you as one of the five players until the reset at 11:59 PM.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: state.isFull
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showStackMembers(
    BuildContext context,
    ValorantStackState state,
  ) async {
    final members = state.members;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Who has pushed it today?'),
          content: SizedBox(
            width: double.maxFinite,
            child: members.isEmpty
                ? const Text('No one has pushed the button yet today.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (_, index) {
                      final member = members[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(
                          member.displayName.isEmpty
                              ? 'Unknown player'
                              : member.displayName,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _StackActionCard extends StatelessWidget {
  final ValorantStackState state;
  final bool hasJoinedStack;
  final bool canJoinStack;
  final VoidCallback onShowMembersPressed;
  final Future<void> Function() onJoinPressed;

  const _StackActionCard({
    required this.state,
    required this.hasJoinedStack,
    required this.canJoinStack,
    required this.onShowMembersPressed,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 310,
      child: ElevatedButton(
        onPressed: canJoinStack ? onJoinPressed : null,
        onLongPress: onShowMembersPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: state.isFull
              ? Colors.grey.shade700
              : colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_rounded, color: colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  'Valorant 5 Stack',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${state.count}/5 pushed today',
              style: TextStyle(
                color: colorScheme.onPrimary.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.isFull
                  ? 'Full for today'
                  : hasJoinedStack
                  ? 'You are already on the list'
                  : 'Resets daily at 11:59 PM',
              style: TextStyle(
                color: colorScheme.onPrimary.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatActionButton extends StatelessWidget {
  final bool hasUnreadMessages;
  final VoidCallback onPressed;

  const _ChatActionButton({
    required this.hasUnreadMessages,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.forum, color: colorScheme.onSecondary),
          label: Text(
            'Open Chatroom',
            style: TextStyle(color: colorScheme.onSecondary),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            side: const BorderSide(color: Colors.white, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (hasUnreadMessages)
          const Positioned(
            top: -2,
            right: -2,
            child: CircleAvatar(radius: 6, backgroundColor: Colors.red),
          ),
      ],
    );
  }
}
