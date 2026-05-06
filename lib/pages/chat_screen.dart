import 'package:flutter/material.dart';

import '../components/chatScreen/message_input.dart';
import '../components/chatScreen/messages_list.dart';
import '../services/auth/auth_service.dart';
import '../services/chat/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  static const String _peerAvatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB7k2Pn9IVwL3N9QBk8FxxLqgw1akTQh6f4qkq5iWwW0Q3ifBxbOW9hN8xCBu7S9E8KYnC4QhQvL4AwPZ5uw7m9YfWl3nTQYwQ6w8b7';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage('', text);
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // build UI

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black12,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline))],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessagesList(chatService: _chatService, authService: _authService, peerAvatarUrl: _peerAvatarUrl),
          ),
          MessageInput(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }

  // Message row and avatar builders were moved to separate widgets in lib/pages/widgets/
}
