import 'package:flutter/material.dart';

/// A simple app bar shared by all build states of OrderDetailsScreen.
class OrderDetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OrderDetailsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Order Details'),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
