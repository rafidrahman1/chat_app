import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/settings_screen.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  //logout function
  void logout() {
    final _auth = FirebaseAuth.instance;
    _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(color: colorScheme.onSecondary, fontSize: 24, fontWeight: FontWeight.bold),
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
            title: Text('Settings', style: TextStyle(color: colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
          ),
          Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: Icon(Icons.logout, color: colorScheme.onSurface),
              title: Text('Logout', style: TextStyle(color: colorScheme.onSurface)),
              onTap: logout,
            ),
          ),
        ],
      ),
    );
  }
}
