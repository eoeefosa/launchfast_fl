import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../utils/price_calculator.dart';

class OrderSummarySection extends StatelessWidget {
  final CartProvider cart;
  final DeliveryType deliveryType;

  const OrderSummarySection({
    super.key,
    required this.cart,
    required this.deliveryType,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text('${cart.totalQuantity} Items'),
      children: [
        ...cart.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.menuItem.name}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text('₦${PriceCalculator.calculateCartItemPrice(
                  item,
                  meatPrices: context.read<StoreProvider>().meatPrices,
                  saladPrice: context.read<StoreProvider>().saladPrice,
                  allMenuItems: context.read<StoreProvider>().menuItems,
                ).toStringAsFixed(0)}'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 4),
        _row(context, 'Subtotal', cart.subTotal),
        _row(context, 'Service Charge', cart.serviceFees),
        _row(context, 'Delivery Charge', deliveryType.charge,
            valueLabel: deliveryType.charge == 0 ? 'FREE' : null),
      ],
    );
  }

  Widget _row(BuildContext context, String label, double value, {String? valueLabel}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            valueLabel ?? '₦${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueLabel == 'FREE' ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }
}
