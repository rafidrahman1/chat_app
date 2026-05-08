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
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _favoriteAgentController =
      TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  bool _hasSeededController = false;
  bool _saving = false;

  void _seedController({
    required String name,
    required String nickname,
    required String favoriteAgent,
    required String role,
  }) {
    if (_hasSeededController) return;
    _nameController.text = name;
    _nicknameController.text = nickname;
    _favoriteAgentController.text = favoriteAgent;
    _roleController.text = role;
    _hasSeededController = true;
  }

  Future<void> _saveName(User user) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(userServiceProvider)
          .upsertUserProfile(
            uid: user.uid,
            displayName: newName,
            photoUrl: user.photoURL ?? '',
            nickname: _nicknameController.text.trim(),
            favoriteAgent: _favoriteAgentController.text.trim(),
            role: _roleController.text.trim(),
          );
      await user.updateDisplayName(newName);
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name updated')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to update name')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to update name')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _favoriteAgentController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final usersState = ref.watch(userProfilesProvider);
    final user = authState.asData?.value;
    final profiles = usersState.asData?.value;
    final colorScheme = Theme.of(context).colorScheme;

    if (authState.isLoading || usersState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profileName = user == null
        ? ''
        : (profiles?[user.uid]?.displayName.trim() ?? '');
    final authName = (user?.displayName ?? '').trim();
    final currentName = profileName.isNotEmpty ? profileName : authName;
    final currentNickname = user == null
        ? ''
        : (profiles?[user.uid]?.nickname ?? '');
    final currentFavoriteAgent = user == null
        ? ''
        : (profiles?[user.uid]?.favoriteAgent ?? '');
    final currentRole = user == null ? '' : (profiles?[user.uid]?.role ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _seedController(
          name: currentName,
          nickname: currentNickname,
          favoriteAgent: currentFavoriteAgent,
          role: currentRole,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: user == null
          ? const Center(child: Text('Please sign in to edit your name.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  title: 'Profile',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your name',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveName(user),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Nickname (e.g. Deadshot)',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _favoriteAgentController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Favorite agent (e.g. Jett)',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _roleController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Role (e.g. Duelist)',
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _saveName(user),
                          style: _primaryButtonStyle(colorScheme),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Sync User Items',
                  child: ElevatedButton(
                    onPressed: () async {},
                    style: _primaryButtonStyle(colorScheme),
                    child: const Text(
                      'Sync Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  ButtonStyle _primaryButtonStyle(ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      side: const BorderSide(color: Colors.white, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
