import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CheckoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CheckoutAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close_rounded, color: scheme.onSurface),
        ),
      ),
      title: Text(
        'Checkout',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
