import 'package:cached_network_image/cached_network_image.dart';
import 'package:deadshot/components/my_drawer.dart';
import 'package:deadshot/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

import '../routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    final avatar = user?.photoURL != null
        ? CircleAvatar(radius: 16, backgroundImage: CachedNetworkImageProvider(user!.photoURL!))
        : const CircleAvatar(radius: 16, child: Icon(Icons.person));

    final displayName = user?.displayName ?? 'Home';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(displayName, style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis),
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
            label: const Text('Open Chatroom', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
