import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _hasSeededController = false;
  bool _saving = false;

  void _seedController(String name) {
    if (_hasSeededController) return;
    _nameController.text = name;
    _hasSeededController = true;
  }

  Future<void> _saveName(User user) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).upsertUserProfile(uid: user.uid, displayName: newName, photoUrl: user.photoURL ?? '');
      await user.updateDisplayName(newName);
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Unable to update name')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update name')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final usersState = ref.watch(userProfilesProvider);
    final user = authState.asData?.value;
    final profiles = usersState.asData?.value;

    if (authState.isLoading || usersState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profileName = user == null ? '' : (profiles?[user.uid]?.displayName.trim() ?? '');
    final authName = (user?.displayName ?? '').trim();
    final currentName = profileName.isNotEmpty ? profileName : authName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _seedController(currentName);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: user == null
          ? const Center(child: Text('Please sign in to edit your name.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter your name'),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveName(user),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _saving ? null : () => _saveName(user),
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () {
                                _nameController.clear();
                              },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
