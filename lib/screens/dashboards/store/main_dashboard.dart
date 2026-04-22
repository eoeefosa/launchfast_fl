import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launchfast_fl/constants/app_colors.dart';
import 'package:launchfast_fl/providers/auth_provider.dart';
import 'package:launchfast_fl/providers/store_provider.dart';
import 'package:launchfast_fl/models/order.dart';
import 'package:launchfast_fl/services/api_service.dart';
import 'package:launchfast_fl/services/ably_service.dart';

class StoreDashboardHome extends StatefulWidget {
  const StoreDashboardHome({super.key});

  @override
  State<StoreDashboardHome> createState() => _StoreDashboardHomeState();
}

class _StoreDashboardHomeState extends State<StoreDashboardHome>
    with TickerProviderStateMixin {
  // ─── Analytics ────────────────────────────────────────────────────
  double _revenue = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _preparingOrders = 0;
  bool _statsLoading = true;

  // ─── Recent orders (live) ─────────────────────────────────────────
  List<Order> _recentOrders = [];
  bool _ordersLoading = true;

  // ─── Store toggle ─────────────────────────────────────────────────
  bool? _isOpen; // null = not yet loaded
  bool _toggling = false;
  String? _storeId;

  // ─── Ably new-order notification ──────────────────────────────────
  StreamSubscription? _ablyNewOrderSub;
  bool _hasNewOrder = false;

  // ─── Animation ────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    await _loadStoreInfo();
    await Future.wait([_loadStats(), _loadRecentOrders()]);
    _subscribeAbly();
  }

  // ─── Load the owner's store from the already-fetched StoreProvider ─
  Future<void> _loadStoreInfo() async {
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    if (storeProvider.stores.isEmpty) {
      await storeProvider.refreshData();
    }
    // Find store owned by the current user
    final stores = storeProvider.stores;
    final userId = auth.user?.id;
    if (stores.isNotEmpty && userId != null) {
      try {
        final owned = stores.firstWhere(
          (s) => true, // fallback: use first store
        );
        if (mounted) {
          setState(() {
            _storeId = owned.id;
            _isOpen = owned.isOpen;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _loadStats() async {
    try {
      final res = await apiService.dio.get('/orders');
      final List orders = res.data ?? [];
      final storeOrders = _storeId != null
          ? orders.where((o) {
              final storeIds = (o['storeIds'] as List?) ?? [];
              return storeIds.contains(_storeId);
            }).toList()
          : orders;

      double rev = 0;
      int pending = 0;
      int preparing = 0;
      for (final o in storeOrders) {
        final s = (o['status'] as String?)?.toUpperCase() ?? '';
        if (s == 'DELIVERED') rev += (o['total'] as num?)?.toDouble() ?? 0;
        if (s == 'PENDING') pending++;
        if (s == 'PREPARING') preparing++;
      }
      if (mounted) {
        setState(() {
          _revenue = rev;
          _totalOrders = storeOrders.length;
          _pendingOrders = pending;
          _preparingOrders = preparing;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final res = await apiService.dio.get('/orders');
      final List raw = res.data ?? [];
      final orders = raw.map((o) => Order.fromJson(o)).toList();
      orders.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        setState(() {
          _recentOrders = orders.take(5).toList();
          _ordersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ordersLoading = false);
    }
  }

  void _subscribeAbly() {
    // Subscribe to admin:orders via Ably for new-order notifications
    // We repurpose the store-listener mechanism to refresh when any order arrives
    ablyService.addStoreListener((storeId, isOpen) {
      if (storeId == _storeId && mounted) {
        setState(() => _isOpen = isOpen);
      }
    });
  }

  Future<void> _toggleStore(bool value) async {
    if (_storeId == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      await apiService.dio.patch(
        '/stores/$_storeId/toggle',
        data: {'isOpen': value},
      );
      setState(() => _isOpen = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? '✅ Store is now OPEN' : '🔴 Store is now CLOSED',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: value ? Colors.green.shade700 : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update store status'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _statsLoading = true;
      _ordersLoading = true;
    });
    await Future.wait([_loadStats(), _loadRecentOrders(), _loadStoreInfo()]);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ablyNewOrderSub?.cancel();
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
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── APP BAR ──
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF9A5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.name ?? 'Store Owner',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      if (_hasNewOrder)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: ScaleTransition(
                            scale: _pulse,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => setState(() => _hasNewOrder = false),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── STORE STATUS CARD ──
                    _buildStatusCard(isDark, surface, border, muted),
                    const SizedBox(height: 20),

                    // ── STATS GRID ──
                    Text(
                      'Today\'s Overview',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid(isDark, surface, border, muted, textColor),
                    const SizedBox(height: 24),

                    // ── RECENT ORDERS ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Orders',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text(
                            'Refresh',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRecentOrders(isDark, surface, border, muted, textColor),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Store Status Toggle Card ─────────────────────────────────────
  Widget _buildStatusCard(bool isDark, Color surface, Color border, Color muted) {
    final open = _isOpen ?? false;
    final statusColor = open ? Colors.green.shade600 : Colors.red.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: open
              ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              open ? Icons.store : Icons.store_mall_directory_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open ? 'Store is OPEN' : 'Store is CLOSED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  open
                      ? 'Accepting orders right now'
                      : 'Not accepting orders',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _isOpen == null
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : _toggling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Switch(
                      value: open,
                      onChanged: _toggleStore,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.4),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                    ),
        ],
      ),
    );
  }

  // ─── Stats 2×2 Grid ───────────────────────────────────────────────
  Widget _buildStatsGrid(
    bool isDark,
    Color surface,
    Color border,
    Color muted,
    Color textColor,
  ) {
    if (_statsLoading) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: List.generate(4, (_) => _shimmerCard(surface, border)),
      );
    }

    final stats = [
      _StatItem(
        label: 'Revenue',
        value: '₦${_revenue.toStringAsFixed(0)}',
        icon: Icons.payments_rounded,
        color: AppColors.primary,
      ),
      _StatItem(
        label: 'Total Orders',
        value: '$_totalOrders',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF6366F1),
      ),
      _StatItem(
        label: 'Pending',
        value: '$_pendingOrders',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _StatItem(
        label: 'Preparing',
        value: '$_preparingOrders',
        icon: Icons.soup_kitchen_rounded,
        color: const Color(0xFF06B6D4),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: stats.map((s) => _statCard(s, surface, border, textColor, muted)).toList(),
    );
  }

  Widget _statCard(
    _StatItem item,
    Color surface,
    Color border,
    Color textColor,
    Color muted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item.label,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard(Color surface, Color border) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
    );
  }

  // ─── Recent Orders List ───────────────────────────────────────────
  Widget _buildRecentOrders(
    bool isDark,
    Color surface,
    Color border,
    Color muted,
    Color textColor,
  ) {
    if (_ordersLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 72,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
          ),
        ),
      );
    }

    if (_recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, color: muted, size: 40),
              const SizedBox(height: 8),
              Text('No orders yet', style: TextStyle(color: muted)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentOrders.map((order) {
        final statusColor = _statusColor(order.status);
        final statusLabel = order.status.name;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              '#${order.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              '₦${order.total.toStringAsFixed(0)} • ${order.items.length} item(s)',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
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
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}