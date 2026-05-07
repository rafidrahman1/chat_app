import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../routes.dart';

class MyDrawer extends ConsumerWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.primary,
      child: Column(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.secondary),
            child: Center(
              child: Text(
                'Deadshot',
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: colorScheme.onSurface),
            title: Text('Home', style: TextStyle(color: colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: colorScheme.onSurface),
            title: Text(
              'Settings',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
          Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: Icon(Icons.logout, color: colorScheme.onSurface),
              title: Text(
                'Logout',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
