import 'package:deadshot/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pages/home_screen.dart';
import '../../providers/app_providers.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();

    ref.listen(authStateChangesProvider, (previous, next) async {
      final user = next.asData?.value;
      if (user == null) return;
      await ref.read(authServiceProvider).cacheCurrentUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const LoginScreen(),
    );
  }
}
