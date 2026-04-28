import 'package:flutter/material.dart';

class ClearNotificationsDialog extends StatelessWidget {
  const ClearNotificationsDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clear all notifications?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text(
            'Clear All',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
