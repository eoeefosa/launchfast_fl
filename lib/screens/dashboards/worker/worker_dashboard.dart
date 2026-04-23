import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launchfast/constants/app_colors.dart';
import 'package:launchfast/providers/auth_provider.dart';
import 'package:launchfast/providers/store_provider.dart';
import 'package:launchfast/services/api_service.dart';
import 'package:launchfast/services/ably_service.dart';
// import 'package:launchfast/models/order.dart';
import 'package:intl/intl.dart';

class WorkerDashboardHome extends StatefulWidget {
  const WorkerDashboardHome({super.key});

  @override
  State<WorkerDashboardHome> createState() => _WorkerDashboardHomeState();
}

class _WorkerDashboardHomeState extends State<WorkerDashboardHome>
    with TickerProviderStateMixin {
  // ─── Operational Stats (No Revenue) ───────────────────────────────
  int _totalOrders = 0;
  int _pendingCount = 0;
  int _preparingCount = 0;
  int _readyCount = 0;

  List<dynamic> _recentOrders = [];
  bool _isLoading = true;
  String? _storeId;
  String? _storeName;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadStoreInfo();
    await Future.wait([_loadStats(), _loadRecentOrders()]);
    _subscribeAbly();
  }

  Future<void> _loadStoreInfo() async {
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();

    // For a worker, we use their adminStore field
    final assignedStoreId = auth.user?.adminStore;

    if (storeProvider.stores.isEmpty) await storeProvider.refreshData();

    final stores = storeProvider.stores;
    if (assignedStoreId != null) {
      try {
        final store = stores.firstWhere((s) => s.id == assignedStoreId);
        if (mounted) {
          setState(() {
            _storeId = store.id;
            _storeName = store.name;
            _isOpen = store.isOpen;
          });
        }
      } catch (_) {}
    } else if (stores.isNotEmpty) {
      // Fallback if adminStore not set
      final store = stores.first;
      if (mounted) {
        setState(() {
          _storeId = store.id;
          _storeName = store.name;
          _isOpen = store.isOpen;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final res = await apiService.dio.get('/orders');
      final List orders = res.data ?? [];

      final storeOrders = _storeId != null
          ? orders.where((o) {
              final sIds = (o['storeIds'] as List?) ?? [];
              return sIds.contains(_storeId);
            }).toList()
          : orders;

      if (mounted) {
        setState(() {
          _totalOrders = storeOrders.length;
          _pendingCount = storeOrders
              .where((o) => o['status'] == 'PENDING')
              .length;
          _preparingCount = storeOrders
              .where((o) => o['status'] == 'PREPARING')
              .length;
          _readyCount = storeOrders
              .where((o) => o['status'] == 'READY_FOR_PICKUP')
              .length;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecentOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.dio.get('/orders');
      final List orders = res.data ?? [];

      final filtered = _storeId != null
          ? orders.where((o) {
              final sIds = (o['storeIds'] as List?) ?? [];
              return sIds.contains(_storeId);
            }).toList()
          : orders;

      if (mounted) {
        setState(() {
          _recentOrders = filtered.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeAbly() {
    ablyService.addOrderListener((orderId, status) {
      _loadStats();
      _loadRecentOrders();
    });

    ablyService.addStoreListener((storeId, isOpen) {
      if (storeId == _storeId && mounted) {
        setState(() => _isOpen = isOpen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreStatusCard(isDark, textColor, muted),
                  const SizedBox(height: 24),
                  Text(
                    'Operational Overview',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOperationalGrid(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {}, // Navigate to Orders
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecentOrdersList(isDark, textColor, muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _storeName ?? 'Staff Dashboard',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreStatusCard(bool isDark, Color textColor, Color muted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (_isOpen ? Colors.green : Colors.red).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOpen ? Icons.store_rounded : Icons.store_sharp,
              color: _isOpen ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOpen ? 'Store is Open' : 'Store is Closed',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Current operational status',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Pending',
          '$_pendingCount',
          Icons.hourglass_top,
          Colors.orange,
        ),
        _buildStatCard(
          'Preparing',
          '$_preparingCount',
          Icons.restaurant,
          Colors.blue,
        ),
        _buildStatCard(
          'Ready',
          '$_readyCount',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Total Today',
          '$_totalOrders',
          Icons.list_alt,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList(bool isDark, Color textColor, Color muted) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: muted),
              const SizedBox(height: 12),
              Text('No recent orders', style: TextStyle(color: muted)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentOrders.map((o) {
        final date = DateTime.parse(o['date']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${o['id'].toString().substring(o['id'].toString().length - 5)}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(date),
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(o['status']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  o['status'],
                  style: TextStyle(
                    color: _getStatusColor(o['status']),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PREPARING':
        return Colors.blue;
      case 'READY_FOR_PICKUP':
        return Colors.green;
      case 'DELIVERED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
