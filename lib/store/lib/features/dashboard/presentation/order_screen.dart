import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen>
    with TickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = true;
  OrderStatus? _filter; // null = ALL
  late TabController _tabController;

  static const List<OrderStatus?> _filters = [
    null, // ALL
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  // Ably: badge for new orders
  bool _hasNewOrder = false;
  late AnimationController _badgePulse;
  late Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _filter = _filters[_tabController.index]);
      }
    });

    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _badgeScale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _badgePulse, curve: Curves.easeInOut));

    _loadOrders();
    _subscribeAbly();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final storeProvider = context.read<StoreProvider>();
      final orders = await storeProvider.fetchStoreOrders();
      orders.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      debugPrint('[OrderScreen] _loadOrders error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load orders'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeAbly() {
    // New orders from Ably are pushed on admin:orders channel
    // We listen via addOrderListener (existing infrastructure)
    ablyService.addOrderListener((orderId, status) {
      _loadOrders();
      if (mounted) setState(() => _hasNewOrder = true);
    });
  }

  List<Order> get _filtered {
    if (_filter == null) return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  Future<void> _updateStatus(String orderId, OrderStatus newStatus) async {
    try {
      final storeProvider = context.read<StoreProvider>();
      await storeProvider.updateOrderStatus(orderId, newStatus.backendName);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${newStatus.name}'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[OrderScreen] _updateStatus error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update order'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _badgePulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Row(
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (_hasNewOrder)
              ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadOrders();
              setState(() => _hasNewOrder = false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: _filters.map((f) => Tab(text: _tabLabel(f))).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadOrders,
              child: _filtered.isEmpty
                  ? _emptyState(muted)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _OrderCard(
                        order: _filtered[i],
                        textColor: textColor,
                        muted: muted,
                        surface: surface,
                        border: border,
                        onUpdateStatus: _updateStatus,
                      ),
                    ),
            ),
    );
  }

  String _tabLabel(OrderStatus? filter) {
    if (filter == null) return 'All';
    return filter.name;
  }

  Widget _emptyState(Color muted) {
    return Center(
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
    );
  }
}

// ─── Individual Order Card ─────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  final Color textColor;
  final Color muted;
  final Color surface;
  final Color border;
  final Future<void> Function(String orderId, OrderStatus status) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.textColor,
    required this.muted,
    required this.surface,
    required this.border,
    required this.onUpdateStatus,
  });

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.accepted:
        return const Color(0xFF6366F1);
      case OrderStatus.preparing:
        return const Color(0xFF06B6D4);
      case OrderStatus.readyForPickup:
      case OrderStatus.pickingUp:
        return const Color(0xFF8B5CF6);
      case OrderStatus.onTheWay:
      case OrderStatus.outForDelivery:
        return AppColors.primary;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return AppColors.lightMuted;
    }
  }

  List<_ActionBtn> get _actions {
    switch (order.status) {
      case OrderStatus.pending:
        return [
          _ActionBtn(
            'Accept',
            OrderStatus.accepted,
            Colors.green,
            Icons.check_circle_outline,
          ),
          _ActionBtn('Reject', OrderStatus.cancelled, Colors.red, Icons.cancel_outlined),
        ];
      case OrderStatus.accepted:
        return [
          _ActionBtn(
            'Start Preparing',
            OrderStatus.preparing,
            const Color(0xFF06B6D4),
            Icons.soup_kitchen_outlined,
          ),
        ];
      case OrderStatus.preparing:
        return [
          _ActionBtn(
            'Mark Ready',
            OrderStatus.readyForPickup,
            const Color(0xFF8B5CF6),
            Icons.done_all,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$shortId',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _formatDate(order.date),
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.status.name,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: border, height: 1),
            const SizedBox(height: 12),

            // ── Customer Info ──
            if (order.user != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.user!.name,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (order.user!.phone != null && order.user!.phone!.isNotEmpty)
                          Text(
                            order.user!.phone!,
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  if (order.user!.phone != null && order.user!.phone!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.primary),
                      onPressed: () async {
                        final uri = Uri.parse('tel:${order.user!.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),
            ],

            // ── Items ──
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}× ${item.menuItem.name}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '₦${((item.menuItem.price) * item.quantity).toStringAsFixed(0)}',
                          style: TextStyle(color: muted, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (item.hasSalad)
                      Text('• Salad', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (item.extras != null && item.extras!.isNotEmpty)
                      Text('• Extras: ${item.extras!.join(", ")}', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (item.selectedMeats != null && item.selectedMeats!.isNotEmpty)
                      ...item.selectedMeats!.entries.map((e) => Text('• Meat: ${e.key} (x${e.value})', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600))),
                    if (item.selectedAddons != null && item.selectedAddons!.isNotEmpty)
                      ...item.selectedAddons!.entries.map((e) => Text('• Addon: ${e.key} (x${e.value})', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Divider(color: border, height: 1),
            const SizedBox(height: 12),

            // ── Total + Priority ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(color: muted, fontSize: 13)),
                Row(
                  children: [
                    if (order.isPriority)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚡ Priority',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      '₦${order.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Action Buttons ──
            if (_actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _actions
                    .map((a) => _buildActionButton(context, a))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, _ActionBtn btn) {
    return ElevatedButton.icon(
      onPressed: () => onUpdateStatus(order.id, btn.status),
      icon: Icon(btn.icon, size: 16),
      label: Text(btn.label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: btn.color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day}/${dt.month}/${dt.year} • $h:$m $ampm';
    } catch (_) {
      return iso;
    }
  }
}

class _ActionBtn {
  final String label;
  final OrderStatus status;
  final Color color;
  final IconData icon;
  const _ActionBtn(this.label, this.status, this.color, this.icon);
}
