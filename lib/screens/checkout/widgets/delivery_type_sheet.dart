import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../providers/cart_provider.dart';
import 'selection_dialog.dart';
import 'selection_option.dart';

class DeliveryTypeSheet extends StatelessWidget {
  final DeliveryType currentType;
  final ValueChanged<DeliveryType> onTypeSelected;

  const DeliveryTypeSheet({
    super.key,
    required this.currentType,
    required this.onTypeSelected,
  });

  static void show(BuildContext context, DeliveryType current, ValueChanged<DeliveryType> onSelected) {
    showDialog(
      context: context,
      builder: (context) => DeliveryTypeSheet(
        currentType: current,
        onTypeSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      title: 'Delivery Type',
      options: [
        _option(context, DeliveryType.bulk, '₦300 • Wait for nearby packages'),
        _option(context, DeliveryType.priority, '₦1,300 • Processed immediately'),
        _option(context, DeliveryType.pickup, 'FREE • Collect from the store'),
      ],
    );
  }

  SelectionOption _option(BuildContext context, DeliveryType type, String subtitle) {
    return SelectionOption(
      title: type.label,
      subtitle: subtitle,
      icon: _iconForDeliveryType(type),
      isSelected: currentType == type,
      onTap: () {
        HapticFeedback.selectionClick();
        onTypeSelected(type);
        Navigator.pop(context);
      },
    );
  }

  IconData _iconForDeliveryType(DeliveryType type) {
    switch (type) {
      case DeliveryType.priority:
        return Icons.bolt_rounded;
      case DeliveryType.pickup:
        return Icons.store_rounded;
      case DeliveryType.bulk:
        return Icons.local_shipping_rounded;
    }
  }
}
