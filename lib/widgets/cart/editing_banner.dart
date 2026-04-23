import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/cart_provider.dart';

class EditingBanner extends StatelessWidget {
  const EditingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Container(
      width: double.infinity,
      color: Colors.amber[50],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_note_rounded, size: 20, color: Colors.amber[900]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing Order',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.amber[900],
                  ),
                ),
                Text(
                  'You are currently updating an existing order.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: cart.stopEditing,
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber[900],
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -1);
  }
}
