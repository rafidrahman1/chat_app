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
    final user = ref.watch(authStateChangesProvider).valueOrNull;

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
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
            icon: const Icon(Icons.forum, color: Colors.white),
            label: const Text(
              'Open Chatroom',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
