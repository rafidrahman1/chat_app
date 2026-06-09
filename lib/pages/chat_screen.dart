import 'dart:async';

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
  AppLifecycleState? _lastLifecycleState;
  late final _ChatLifecycleObserver _lifecycleObserver;
  Timer? _presenceHeartbeat;
  bool _presenceSetOnline = false;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _ChatLifecycleObserver(_onLifecycleChanged);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) => _setPresence(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _presenceHeartbeat?.cancel();
    _setPresence(false);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await ref.read(chatServiceProvider).sendTextMessage(text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  Future<void> _createPoll() async {
    final controller = TextEditingController();
    final question = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create yes/no poll'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Queue tonight?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text(
                'Post poll',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (question == null || question.isEmpty) return;

    try {
      await ref.read(chatServiceProvider).sendYesNoPoll(question);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create poll: $e')));
    }
  }

  Future<void> _setPresence(bool isOnline) async {
    if (!mounted) return;
    if (isOnline && _presenceSetOnline) return;
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) return;
    _presenceSetOnline = isOnline;
    if (isOnline) {
      _presenceHeartbeat ??= Timer.periodic(const Duration(minutes: 1), (_) {
        _setPresence(true);
      });
    } else {
      _presenceHeartbeat?.cancel();
      _presenceHeartbeat = null;
    }
    try {
      await ref
          .read(userServiceProvider)
          .setOnlineStatus(uid: user.uid, isOnline: isOnline);
    } catch (_) {}
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    if (_lastLifecycleState == state) return;
    _lastLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _setPresence(true);
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _setPresence(false);
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
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: Column(
        children: [
          const Expanded(child: MessagesList()),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            onCreatePoll: _createPoll,
          ),
        ],
      ),
    );
  }

  // Message row and avatar builders were moved to separate widgets in lib/pages/widgets/
}

class _ChatLifecycleObserver extends WidgetsBindingObserver {
  final ValueChanged<AppLifecycleState> onChanged;

  _ChatLifecycleObserver(this.onChanged);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onChanged(state);
  }
}
