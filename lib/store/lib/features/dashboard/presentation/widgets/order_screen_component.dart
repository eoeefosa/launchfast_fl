import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';

class OrderAppBarTitle extends StatelessWidget {
  const OrderAppBarTitle({
    super.key,
    required this.hasNewOrder,
    required this.badgeScale,
  });

  final bool hasNewOrder;
  final Animation<double> badgeScale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hasNewOrder) ...[
          const SizedBox(width: 8),
          ScaleTransition(
            scale: badgeScale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class OrderSearchBar extends StatelessWidget {
  const OrderSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.bg,
    required this.surface,
    required this.muted,
    required this.border,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final Color bg;
  final Color surface;
  final Color muted;
  final Color border;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search by Order ID or Name',
            prefixIcon: Icon(Icons.search, color: muted),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: muted),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: surface,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({super.key, required this.muted});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: muted),
              const SizedBox(height: 12),
              Text(
                'No orders in this category',
                style: TextStyle(color: muted, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PickupConfirmDialog extends StatelessWidget {
  const PickupConfirmDialog({
    super.key,
    required this.shortCode,
    required this.customerName,
  });

  final String shortCode;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirm Pickup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hand the order to $customerName\nand mark it as delivered?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Order #$shortCode',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text(
            'Mark Delivered',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
