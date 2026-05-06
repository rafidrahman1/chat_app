import 'package:deadshot/components/my_drawer.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Home')),
      drawer: const MyDrawer(),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
          icon: const Icon(Icons.forum, color: Colors.white),
          label: const Text('Open Chatroom', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
