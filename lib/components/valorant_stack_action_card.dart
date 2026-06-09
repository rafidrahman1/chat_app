import 'package:flutter/material.dart';

import '../model/valorant_stack_state.dart';

class ValorantStackActionCard extends StatelessWidget {
  final ValorantStackState state;
  final bool hasJoinedStack;
  final bool canJoinStack;
  final VoidCallback onShowMembersPressed;
  final Future<void> Function() onJoinPressed;

  const ValorantStackActionCard({
    super.key,
    required this.state,
    required this.hasJoinedStack,
    required this.canJoinStack,
    required this.onShowMembersPressed,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 310,
      child: ElevatedButton(
        onPressed: canJoinStack ? onJoinPressed : null,
        onLongPress: onShowMembersPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: state.isFull
              ? Colors.grey.shade700
              : colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_rounded, color: colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  'Valorant 5 Stack',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${state.count}/5 pushed today',
              style: TextStyle(
                color: colorScheme.onPrimary.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.isFull
                  ? 'Full for today'
                  : hasJoinedStack
                  ? 'You are already on the list'
                  : 'Resets daily at 11:59 PM',
              style: TextStyle(
                color: colorScheme.onPrimary.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
