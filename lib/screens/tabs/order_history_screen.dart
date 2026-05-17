import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../widgets/orders/order_history_card.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final scheme = Theme.of(context).colorScheme;

    // Filter past orders (anything not from today)
    final now = DateTime.now();
    final pastOrders = orderProvider.orders.where((o) {
      try {
        final orderDate = DateTime.parse(o.date);
        return !(orderDate.year == now.year &&
                 orderDate.month == now.month &&
                 orderDate.day == now.day);
      } catch (_) {
        return true; // If parsing fails, treat as past? or today? 
                    // Usually safer to show in history if unsure.
      }
    }).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: scheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ALL PAST'),
            Tab(text: 'TOP ORDERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllPastOrders(orders: pastOrders),
          _TopOrders(orders: orderProvider.orders),
        ],
      ),
    );
  }
}

class _AllPastOrders extends StatelessWidget {
  final List<Order> orders;
  const _AllPastOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyHistory();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderHistoryCard(order: orders[index]),
    );
  }
}

class _TopOrders extends StatelessWidget {
  final List<Order> orders;
  const _TopOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return _EmptyHistory();

    // Logic for "Top Orders": Group orders that have the exact same items
    // and sort by frequency.
    final Map<String, List<Order>> groupedOrders = {};

    for (var order in orders) {
      // Create a key based on item IDs and quantities
      final itemKeys = order.items.map((i) => '${i.id}:${i.quantity}').toList()..sort();
      final key = itemKeys.join('|');
      
      if (groupedOrders.containsKey(key)) {
        groupedOrders[key]!.add(order);
      } else {
        groupedOrders[key] = [order];
      }
    }

    // Sort groups by frequency (descending)
    final sortedKeys = groupedOrders.keys.toList()
      ..sort((a, b) => groupedOrders[b]!.length.compareTo(groupedOrders[a]!.length));

    // Get the latest order from each group to display
    final topOrders = sortedKeys.map((k) => groupedOrders[k]!.first).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: topOrders.length,
      itemBuilder: (context, index) {
        final order = topOrders[index];
        final frequency = groupedOrders[sortedKeys[index]]!.length;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (frequency > 1)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ordered $frequency times',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            OrderHistoryCard(order: order),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No past orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
