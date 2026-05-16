import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Clear-cart confirmation dialog
// ─────────────────────────────────────────────

class ItemDetailClearCartDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const ItemDetailClearCartDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Start a new order?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: Text(
        'Your cart has items from another store. Clear it and add this item?',
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey[600],
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text(
            'Clear & Add',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class ItemUnavailableDialog extends StatelessWidget {
  const ItemUnavailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Item Unavailable',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: const Text(
        'We apologize, but this item has just become unavailable. '
        'You will be returned to the store menu.',
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            // We assume the caller handles the screen pop if needed, 
            // or we can use Navigator.of(context).pop() multiple times.
            // But here we just pop the dialog.
          },
          child: const Text('Back to Menu'),
        ),
      ],
    );
  }
}
