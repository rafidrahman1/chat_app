import 'package:deadshot/components/my_drawer.dart';
import 'package:deadshot/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

import '../components/user_tile.dart';
import '../services/auth/auth_service.dart';
import 'chat_page.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // chat & auth Services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      drawer: MyDrawer(),
      body: _buildUserList(),
    );
  }

  //build a list of users except for the current logged in user
  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUserStream(),
      builder: (context, snapshot) {
        //error
        if (snapshot.hasError) {
          return Center(child: Text("Error loading users"));
        }

        //loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        //return list view
        return ListView(children: snapshot.data!.map<Widget>((userData) => _buildUserListItem(userData, context)).toList());
      },
    );
  }

  //build individual user list item
  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    //display all users except for the current logged in user
    return UserTile(
      text: userData["email"],
      onTap: () {
        //navigate to chat screen with the selected user
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverEmail: userData["email"])));
      },
    );
  }
}
