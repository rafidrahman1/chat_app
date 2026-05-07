import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Small avatar widget used by message rows.
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String? fallbackLabel;
  final double radius;

  const AvatarWidget({
    super.key,
    required this.avatarUrl,
    this.fallbackLabel,
    this.radius = 14,
  });

  String _avatarInitial() {
    final label = (fallbackLabel ?? '').trim();
    if (label.isEmpty) return '';

    final emailPrefix = label.contains('@') ? label.split('@').first : label;
    if (emailPrefix.isEmpty) return '';
    return emailPrefix[0].toUpperCase();
  }

  Widget _fallbackAvatar() {
    final initial = _avatarInitial();
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      child: initial.isEmpty
          ? const Icon(Icons.person, size: 20, color: Colors.white)
          : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = avatarUrl?.trim() ?? '';

    if (trimmedUrl.isEmpty) {
      return _fallbackAvatar();
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, url) => _fallbackAvatar(),
        errorWidget: (_, url, error) => _fallbackAvatar(),
      ),
    );
  }
}
