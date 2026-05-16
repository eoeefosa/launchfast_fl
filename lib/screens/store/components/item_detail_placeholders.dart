import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemDetailLoadingView extends StatelessWidget {
  const ItemDetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ItemDetailErrorView extends StatelessWidget {
  final String message;
  final String? subMessage;

  const ItemDetailErrorView({
    super.key,
    required this.message,
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(subMessage!),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
