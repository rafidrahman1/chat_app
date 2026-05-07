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
    final messages = ref.watch(chatMessagesProvider).asData?.value;
    final lastReadMsgId = ref.watch(lastReadMsgIdProvider);

    if (lastReadMsgId == null && messages != null && messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(lastReadMsgIdProvider.notifier).state = messages.last.msgId;
      });
    }

    final avatar = user?.photoURL != null
        ? CircleAvatar(
            radius: 16,
            backgroundImage: CachedNetworkImageProvider(user!.photoURL!),
          )
        : const CircleAvatar(radius: 16, child: Icon(Icons.person));

    final displayName = user?.displayName ?? 'Home';

    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Scaffold(
        body: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  final latestMsgId = messages?.isNotEmpty == true ? messages!.last.msgId : null;
                  if (latestMsgId != null) {
                    ref.read(lastReadMsgIdProvider.notifier).state = latestMsgId;
                  }
                  Navigator.pushNamed(context, AppRoutes.chat);
                },
                icon: const Icon(Icons.forum, color: Colors.white),
                label: const Text(
                  'Open Chatroom',
                  style: TextStyle(color: Colors.white),
                ),
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
      ),
    );
  }
}
