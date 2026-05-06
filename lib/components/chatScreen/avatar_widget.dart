import 'package:flutter/material.dart';

/// Small avatar widget used by message rows.
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const AvatarWidget({super.key, required this.avatarUrl, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null || avatarUrl!.isEmpty ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
    );
  }
}
