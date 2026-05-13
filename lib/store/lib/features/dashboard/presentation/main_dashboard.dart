import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/status_card.dart';
import 'widgets/top_selling_items.dart';
import 'widgets/stats_grid.dart';
import 'widgets/recent_orders_list.dart';
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
  List<MapEntry<String, int>> _topSellingItems = [];

  // ─── Store toggle ─────────────────────────────────────────────────
  bool? _isOpen; // null = not yet loaded
  bool _toggling = false;
  String? _storeId;

  // ─── Ably new-order notification ──────────────────────────────────
  bool _hasNewOrder = false;

  // ─── Animation & Audio ────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer.setReleaseMode(ReleaseMode.loop).catchError((e) {
        debugPrint('[Dashboard] AudioPlayer setReleaseMode failed: $e');
      });
    } catch (e) {
      debugPrint('[Dashboard] AudioPlayer init failed: $e');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  Future<void> _init() async {
    _loadStoreInfo();
    await Future.wait([_loadStats(), _loadRecentOrders()]);
    _subscribeAbly();
  }

  // ─── Load the owner's store from the StoreProvider ────────────────
  void _loadStoreInfo() {
    final storeProvider = context.read<StoreProvider>();
    final owned = storeProvider.ownedStore;
    if (owned != null && mounted) {
      setState(() {
        _storeId = owned.id;
        _isOpen = owned.isOpen;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final storeProvider = context.read<StoreProvider>();
      final stats = await storeProvider.fetchStoreStats();

      if (mounted) {
        setState(() {
          _revenue = stats.revenue;
          _totalOrders = stats.totalOrders;
          _pendingOrders = stats.pendingOrders;
          _preparingOrders = stats.preparingOrders;
          _topSellingItems = stats.topSellingItems.entries.toList();
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load store statistics')),
        );
      }
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final storeProvider = context.read<StoreProvider>();
      final orders = await storeProvider.fetchStoreOrders();
          
      orders.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        setState(() {
          _recentOrders = orders.take(5).toList();
          _ordersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ordersLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load recent orders')),
        );
      }
    }
  }

  void _subscribeAbly() {
    ablyService.addStoreListener(_onStoreToggle);
    ablyService.addOrderListener(_onNewOrder);
  }

  Future<void> _onStoreToggle(String storeId, bool isOpen) async {
    if (storeId == _storeId && mounted) {
      setState(() {
        _isOpen = isOpen;
      });
    }
  }

  void _onNewOrder(String orderId, OrderStatus status) {
    if (status == OrderStatus.pending && mounted) {
      setState(() => _hasNewOrder = true);
      _pulseCtrl.repeat(reverse: true);
      _refresh(); // Auto-refresh data to show the new order in the list
      
      try {
        _audioPlayer.play(AssetSource('notification.mp3'));
      } catch (e) {
        debugPrint('[Dashboard] Audio playback failed: $e');
      }
    }
  }

  Future<void> _toggleStore(bool value) async {
    if (_storeId == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      final storeProvider = context.read<StoreProvider>();
      await storeProvider.toggleStoreStatus(value);
      if (mounted) setState(() => _isOpen = value);
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
    _loadStoreInfo();
    await Future.wait([_loadStats(), _loadRecentOrders()]);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    ablyService.removeStoreListener(_onStoreToggle);
    ablyService.removeOrderListener(_onNewOrder);
    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('[Dashboard] AudioPlayer dispose error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final user = context.select<AuthProvider, dynamic>((p) => p.user);

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
                      colors: [AppColors.primary, AppColors.primary],
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
                          color: Colors.white.withValues(alpha: 0.85),
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
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
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
                  onPressed: () {
                    setState(() => _hasNewOrder = false);
                    _pulseCtrl.stop();
                    _pulseCtrl.reset();
                    _audioPlayer.stop();
                  },
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
                    DashboardStatusCard(
                      isOpen: _isOpen ?? false,
                      toggling: _toggling || _isOpen == null,
                      onToggle: _toggleStore,
                    ),
                    const SizedBox(height: 12),
                    
                    // ── BUSY MODE BUTTON ──
                    if (_isOpen == true) ...[
                      ElevatedButton.icon(
                        onPressed: () => _toggleStore(false),
                        icon: const Icon(Icons.pause_circle_filled),
                        label: const Text(
                          'BUSY MODE: PAUSE ORDERS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],

                    // ── TOP SELLING ITEMS ──
                    DashboardTopSellingItems(
                      isLoading: _statsLoading,
                      items: _topSellingItems,
                    ),

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
                    DashboardStatsGrid(
                      isLoading: _statsLoading,
                      revenue: _revenue,
                      totalOrders: _totalOrders,
                      pendingOrders: _pendingOrders,
                      preparingOrders: _preparingOrders,
                    ),
                    const SizedBox(height: 24),

                    // ── RECENT ORDERS ──
                    DashboardRecentOrdersList(
                      isLoading: _ordersLoading,
                      orders: _recentOrders,
                      onRefresh: _refresh,
                    ),
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
}
