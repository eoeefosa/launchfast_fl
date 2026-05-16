import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'widgets/pickup_scanner_sheet.dart';
import 'widgets/order_card.dart';
import 'widgets/order_screen_component.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kFilters = <OrderStatus?>[
  null, // All
  OrderStatus.pending,
  OrderStatus.preparing,
  OrderStatus.readyForPickup,
  OrderStatus.delivered,
  OrderStatus.cancelled,
];

// ─────────────────────────────────────────────────────────────────────────────
// StoreOrdersScreen
// ─────────────────────────────────────────────────────────────────────────────

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  List<Order> _orders = [];
  bool _isLoading = true;
  bool _hasNewOrder = false;
  String _searchQuery = '';

  // ── Controllers ────────────────────────────────────────────────────────────
  late final TabController _tabController;
  late final TextEditingController _searchController;
  late final AnimationController _badgePulse;
  late final Animation<double> _badgeScale;

  // ── Derived ────────────────────────────────────────────────────────────────
  OrderStatus? get _activeFilter => _kFilters[_tabController.index];

  List<Order> get _filtered {
    var list = _orders;

    final filter = _activeFilter;
    if (filter != null) {
      list = list.where((o) => o.status == filter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) {
        final shortId = _shortId(o.id).toLowerCase();
        return o.id.toLowerCase().contains(q) ||
            shortId.contains(q) ||
            (o.user?.name.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _kFilters.length, vsync: this)
      ..addListener(_onTabChanged);

    _searchController = TextEditingController();

    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _badgeScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _badgePulse, curve: Curves.easeInOut),
    );

    _loadOrders();
    _subscribeAbly();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
    _badgePulse.dispose();
    super.dispose();
  }

  // ── Tab listener ───────────────────────────────────────────────────────────

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final orders = await context.read<StoreProvider>().fetchStoreOrders();
      orders.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() => _orders = orders);
    } catch (e, stack) {
      debugPrint('[StoreOrdersScreen] _loadOrders: $e\n$stack');
      _showSnackBar('Failed to load orders', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String orderId, OrderStatus newStatus) async {
    try {
      await context
          .read<StoreProvider>()
          .updateOrderStatus(orderId, newStatus.backendName);
      await _loadOrders();
      _showSnackBar('Order updated to ${newStatus.name}');
    } catch (e, stack) {
      debugPrint('[StoreOrdersScreen] _updateStatus: $e\n$stack');
      _showSnackBar('Failed to update order', isError: true);
    }
  }

  // ── Ably ───────────────────────────────────────────────────────────────────

  void _subscribeAbly() {
    ablyService.addOrderListener((orderId, status) {
      _loadOrders();
      if (mounted) setState(() => _hasNewOrder = true);
    });
  }

  // ── Pickup scanner ─────────────────────────────────────────────────────────

  Future<void> _openPickupScanner() async {
    if (!mounted) return;

    final scanOrders = _orders.map((o) => ScanOrder(o.id)).toList();
    final confirmedId = await PickupScannerSheet.show(
      context,
      orders: scanOrders,
    );

    if (confirmedId == null || !mounted) return;

    final matched = _orders.cast<Order?>().firstWhere(
          (o) => o!.id == confirmedId,
          orElse: () => null,
        );

    if (matched == null) return;

    if (!_isPickupDeliveryType(matched.deliveryType)) {
      _showSnackBar('This order is not a pickup order.', isWarning: true);
      return;
    }

    if (matched.status != OrderStatus.readyForPickup) {
      _showSnackBar(
        'Order is not ready for pickup (status: ${matched.status.name}).',
        isWarning: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => PickupConfirmDialog(
        shortCode: _shortId(confirmedId).toUpperCase(),
        customerName: matched.user?.name ?? 'Customer',
      ),
    );

    if (confirmed == true && mounted) {
      await _updateStatus(confirmedId, OrderStatus.delivered);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _isPickupDeliveryType(String deliveryType) {
    final t = deliveryType.toLowerCase();
    return t == 'pickup' || t == 'store_pickup';
  }

  static String _shortId(String id) =>
      id.length >= 8 ? id.substring(id.length - 8) : id;

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;
    final color = isError
        ? Colors.red.shade700
        : isWarning
            ? Colors.orange.shade700
            : Colors.green.shade700;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
        title: OrderAppBarTitle(
          hasNewOrder: _hasNewOrder,
          badgeScale: _badgeScale,
        ),
        actions: [
          IconButton(
            tooltip: 'Verify Pickup',
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
            ),
            onPressed: _openPickupScanner,
          ),
          IconButton(
            tooltip: 'Refresh',
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _kFilters
              .map((f) => Tab(text: f == null ? 'All' : f.name))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          OrderSearchBar(
            controller: _searchController,
            query: _searchQuery,
            bg: bg,
            surface: surface,
            muted: muted,
            border: border,
            onChanged: (v) => setState(() => _searchQuery = v),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadOrders,
                    child: _filtered.isEmpty
                        ? OrderEmptyState(muted: muted)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => OrderCard(
                              order: _filtered[i],
                              textColor: textColor,
                              muted: muted,
                              surface: surface,
                              border: border,
                              onUpdateStatus: _updateStatus,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
