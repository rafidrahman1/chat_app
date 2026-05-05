import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.secondary),
            child: Text(
              'Deadshot',
              style: TextStyle(color: colorScheme.onSecondary, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: colorScheme.onSurface),
            title: Text('Home', style: TextStyle(color: colorScheme.onSurface)),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: colorScheme.onSurface),
            title: Text(
              'Settings',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
