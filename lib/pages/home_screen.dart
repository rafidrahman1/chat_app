import 'package:cached_network_image/cached_network_image.dart';
import 'package:deadshot/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final hasUnreadMessages = ref.watch(hasUnreadMessagesProvider);
    final lastReadMsgId = ref.watch(lastReadMsgIdProvider);

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

    final displayName = user?.displayName ?? 'Home';
    final colorScheme = Theme.of(context).colorScheme;

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ElevatedButton.icon(
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
              icon: Icon(Icons.forum, color: colorScheme.onSecondary),
              label: Text(
                'Open Chatroom',
                style: TextStyle(color: colorScheme.onSecondary),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary),
            ),
            if (hasUnreadMessages)
              const Positioned(
                top: -2,
                right: -2,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
