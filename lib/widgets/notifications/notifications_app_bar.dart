import 'package:flutter/material.dart';

class NotificationsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NotificationsAppBar({
    super.key,
    required this.hasNotifications,
    required this.onClearAll,
  });

  final bool hasNotifications;
  final VoidCallback onClearAll;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Theme.of(context).colorScheme.surface,
      title: const Text(
        'Notifications',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        if (hasNotifications)
          TextButton(
            onPressed: onClearAll,
            child: const Text('Clear All'),
          ),
      ],
    );
  }
}
