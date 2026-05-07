import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/chatScreen/message_input.dart';
import '../components/chatScreen/messages_list.dart';
import '../model/message.dart';
import '../providers/app_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await ref.read(chatServiceProvider).sendMessage('', text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ensure UI rebuilds when messages update (the list listens too, but this keeps screen state in sync)
    ref.watch(chatMessagesProvider);

    ref.listen<AsyncValue<List<Message>>>(chatMessagesProvider, (prev, next) {
      final messages = next.asData?.value;
      if (messages == null || messages.isEmpty) return;
      ref.read(lastReadMsgIdProvider.notifier).markRead(messages.last.msgId);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black12,
        titleSpacing: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline))],
      ),
      body: Column(
        children: [
          Expanded(child: MessagesList()),
          MessageInput(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }

  // Message row and avatar builders were moved to separate widgets in lib/pages/widgets/
}
