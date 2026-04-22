import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/order.dart';
import '../../constants/static_data.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'My Orders',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 100,
                  color: Colors.grey[100],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Join LanchFast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to track your delicious meals in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 8,
                      shadowColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeOrder = orders.firstWhere(
      (o) =>
          o.status != OrderStatus.delivered &&
          o.status != OrderStatus.cancelled,
      orElse: () => Order(
        id: '',
        items: [],
        total: 0,
        status: OrderStatus.cancelled,
        date: '',
        stores: [],
        isPriority: false,
      ),
    );

    final hasActiveOrder =
        activeOrder.id.isNotEmpty &&
        activeOrder.status != OrderStatus.cancelled &&
        activeOrder.status != OrderStatus.delivered;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.refreshOrders(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            if (hasActiveOrder) ...[
              const Text(
                'Active Delivery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildTrackerBox(context, activeOrder),
              const SizedBox(height: 40),
            ],
            if (orders.isEmpty)
              _buildEmptyState()
            else ...[
              const Text(
                'Past Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              ...orders.map((o) => _buildOrderCard(context, o)),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 24),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'When you place an order, it will appear here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerBox(BuildContext context, Order order) {
    final statusText = order.status == OrderStatus.queued
        ? 'Pending Approval'
        : order.status == OrderStatus.preparing
        ? 'Preparing Meal'
        : order.status == OrderStatus.outForDelivery
        ? 'Out for Delivery'
        : 'Arrived';

    final rider = order.riderId != null
        ? StaticData.riders.firstWhere((r) => r.id == order.riderId)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ORDER #${order.id.substring(order.id.length - 6).toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.status == OrderStatus.preparing
                                ? 'Your chef is working their magic...'
                                : order.status == OrderStatus.outForDelivery
                                ? 'Hang tight! Food is on the way.'
                                : 'We are confirming your order.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildAnimatedIcon(context, order.status),
                  ],
                ),
                const SizedBox(height: 40),
                _buildTimeline(context, order.status),
              ],
            ),
          ),
          if (rider != null) _buildRiderCard(context, rider),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(BuildContext context, OrderStatus status) {
    IconData icon = Icons.timer_rounded;
    if (status == OrderStatus.preparing) icon = Icons.restaurant_rounded;
    if (status == OrderStatus.outForDelivery) {
      icon = Icons.delivery_dining_rounded;
    }
    if (status == OrderStatus.delivered) icon = Icons.check_circle_rounded;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }

  Widget _buildRiderCard(BuildContext context, dynamic rider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Partner',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  rider.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse('tel:${rider.phoneNumber}')),
            icon: const Icon(
              Icons.phone_in_talk_rounded,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, OrderStatus status) {
    final steps = [
      {'title': 'Confirmed', 'icon': Icons.check_circle_outline_rounded},
      {'title': 'Cooking', 'icon': Icons.outdoor_grill_rounded},
      {'title': 'On Way', 'icon': Icons.moped_rounded},
      {'title': 'Delivered', 'icon': Icons.home_rounded},
    ];

    int currentStep = 0;
    if (status == OrderStatus.preparing) currentStep = 1;
    if (status == OrderStatus.outForDelivery) currentStep = 2;
    if (status == OrderStatus.delivered) currentStep = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.black : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[index]['icon'] as IconData,
                      color: isCompleted ? Colors.white : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index]['title'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCompleted
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isCompleted ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      height: 2,
                      color: index < currentStep
                          ? Colors.black
                          : Colors.grey[200],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final isDelivered = order.status == OrderStatus.delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_outlined,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(order.id.length - 4).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(DateTime.parse(order.date)),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${order.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDelivered ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isDelivered ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  ...order.items.map((i) => _buildDetailItem(i)),
                  const SizedBox(height: 20),
                  if (order.status == OrderStatus.queued)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<CartProvider>().loadOrder(
                            order,
                            isEditing: true,
                          );
                          context.push('/cart');
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit My Selections'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(CartItem i) {
    final addons = [];
    if (i.selectedMeats != null) {
      i.selectedMeats!.forEach((k, v) {
        if (v > 0) addons.add('${v}x $k Meat');
      });
    }
    if (i.hasSalad) addons.add('Salad');
    if (i.selectedAddons != null) {
      i.selectedAddons!.forEach((k, v) {
        if (v > 0) addons.add('${v}x $k');
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${i.quantity}x',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.menuItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (addons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      addons.join(' • '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
