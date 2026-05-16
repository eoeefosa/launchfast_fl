import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/auth/presentation/auth_provider.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';

import 'widgets/recent_orders_list.dart';
import 'widgets/stats_grid.dart';
import 'widgets/status_card.dart';
import 'widgets/top_selling_items.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/busy_mode_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StoreDashboardHome
// ─────────────────────────────────────────────────────────────────────────────

class StoreDashboardHome extends StatefulWidget {
  const StoreDashboardHome({super.key});

  @override
  State<StoreDashboardHome> createState() => _StoreDashboardHomeState();
}

class _StoreDashboardHomeState extends State<StoreDashboardHome>
    with TickerProviderStateMixin {
  // ── Analytics ──────────────────────────────────────────────────────────────
  double _revenue = 0;
  double _foodRevenue = 0;
  double _deliveryRevenue = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _preparingOrders = 0;
  bool _statsLoading = true;

  // ── Recent orders ──────────────────────────────────────────────────────────
  List<Order> _recentOrders = [];
  bool _ordersLoading = true;
  List<MapEntry<String, int>> _topSellingItems = [];

  // ── Store toggle ───────────────────────────────────────────────────────────
  bool? _isOpen; // null = not yet loaded
  bool _toggling = false;
  String? _storeId;

  // ── New-order notification ─────────────────────────────────────────────────
  bool _hasNewOrder = false;

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // ── Audio ──────────────────────────────────────────────────────────────────
  // Nullable so a failed init doesn't crash the screen.
  AudioPlayer? _audioPlayer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _initAudio();

    // Safe to call context.read after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  void _initAudio() {
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setReleaseMode(ReleaseMode.loop).catchError((Object e) {
        debugPrint('[Dashboard] AudioPlayer.setReleaseMode failed: $e');
      });
    } catch (e) {
      debugPrint('[Dashboard] AudioPlayer init failed: $e');
      _audioPlayer = null;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    ablyService
      ..removeStoreListener(_onStoreToggle)
      ..removeOrderListener(_onNewOrder);
    _audioPlayer?.dispose();
    super.dispose();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    _loadStoreInfo();
    await Future.wait([_loadStats(), _loadRecentOrders()]);
    _subscribeAbly();
  }

  void _loadStoreInfo() {
    final owned = context.read<StoreProvider>().ownedStore;
    if (owned == null || !mounted) return;
    setState(() {
      _storeId = owned.id;
      _isOpen = owned.isOpen;
    });
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _loadStats() async {
    try {
      final stats = await context.read<StoreProvider>().fetchStoreStats();
      if (!mounted) return;
      setState(() {
        _revenue = stats.revenue;
        _foodRevenue = stats.foodRevenue;
        _deliveryRevenue = stats.deliveryRevenue;
        _totalOrders = stats.totalOrders;
        _pendingOrders = stats.pendingOrders;
        _preparingOrders = stats.preparingOrders;
        _topSellingItems = stats.topSellingItems.entries.toList();
        _statsLoading = false;
      });
    } catch (e, stack) {
      debugPrint('[Dashboard] _loadStats: $e\n$stack');
      if (!mounted) return;
      setState(() => _statsLoading = false);
      _showSnackBar('Failed to load store statistics');
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final orders = await context.read<StoreProvider>().fetchStoreOrders();
      orders.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _recentOrders = orders.take(5).toList();
        _ordersLoading = false;
      });
    } catch (e, stack) {
      debugPrint('[Dashboard] _loadRecentOrders: $e\n$stack');
      if (!mounted) return;
      setState(() => _ordersLoading = false);
      _showSnackBar('Failed to load recent orders');
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _statsLoading = true;
      _ordersLoading = true;
    });
    _loadStoreInfo();
    await Future.wait([_loadStats(), _loadRecentOrders()]);
  }

  // ── Ably ───────────────────────────────────────────────────────────────────

  void _subscribeAbly() {
    ablyService.addStoreListener(_onStoreToggle);
    ablyService.addOrderListener(_onNewOrder);
    if (_storeId != null) {
      ablyService.subscribeToStoreOrders(_storeId!);
    }
  }

  // Typed as `Future<void>` to match the listener signature.
  Future<void> _onStoreToggle(String storeId, bool isOpen) async {
    if (storeId != _storeId || !mounted) return;
    setState(() => _isOpen = isOpen);
  }

  void _onNewOrder(String orderId, OrderStatus status) {
    if (status != OrderStatus.pending || !mounted) return;
    setState(() => _hasNewOrder = true);
    _pulseCtrl.repeat(reverse: true);
    _refresh();
    _playOrderSound();
  }

  void _playOrderSound() {
    try {
      _audioPlayer?.play(AssetSource('sounds/order_sound.mp3'));
    } catch (e) {
      debugPrint('[Dashboard] Audio playback failed: $e');
    }
  }

  void _dismissNewOrderAlert() {
    setState(() => _hasNewOrder = false);
    _pulseCtrl
      ..stop()
      ..reset();
    _audioPlayer?.stop();
  }

  // ── Store toggle ───────────────────────────────────────────────────────────

  Future<void> _toggleStore(bool value) async {
    if (_storeId == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      await context.read<StoreProvider>().toggleStoreStatus(value);
      if (mounted) setState(() => _isOpen = value);
    } catch (e, stack) {
      debugPrint('[Dashboard] _toggleStore: $e\n$stack');
      _showSnackBar(
        'Failed to update store status',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: isError ? SnackBarBehavior.floating : null,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    // context.select so only the greeting re-renders on user change.
    final userName =
        context.select<AuthProvider, String?>((p) => p.user?.name);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            DashboardAppBar(
              userName: userName,
              hasNewOrder: _hasNewOrder,
              pulse: _pulse,
              onNotificationTap: _dismissNewOrderAlert,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardStatusCard(
                      isOpen: _isOpen ?? false,
                      toggling: _toggling || _isOpen == null,
                      onToggle: _toggleStore,
                    ),
                    const SizedBox(height: 12),
                    if (_isOpen == true) ...[
                      BusyModeButton(onTap: () => _toggleStore(false)),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 8),
                    Text(
                      "Today's Overview",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DashboardStatsGrid(
                      isLoading: _statsLoading,
                      foodRevenue: _foodRevenue,
                      deliveryRevenue: _deliveryRevenue,
                      totalRevenue: _revenue,
                      totalOrders: _totalOrders,
                      pendingOrders: _pendingOrders,
                      preparingOrders: _preparingOrders,
                    ),
                    const SizedBox(height: 24),
                    DashboardTopSellingItems(
                      isLoading: _statsLoading,
                      items: _topSellingItems,
                      orders: _recentOrders,
                    ),
                    const SizedBox(height: 24),
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
