import 'package:deadshot/components/my_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //logout function
  void logout() {
    final _auth = FirebaseAuth.instance;
    _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [IconButton(onPressed: logout, icon: const Icon(Icons.logout))],
      ),
      drawer: MyDrawer(),
      body: const Center(child: Text("Welcome to the Home Screen!")),
    );
  }
}
