import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launchfast/constants/app_colors.dart';
import 'package:launchfast/providers/auth_provider.dart';
import 'package:launchfast/services/ably_service.dart';
import 'package:launchfast/repositories/order_repository.dart';
import 'package:launchfast/models/order.dart';
import 'package:launchfast/screens/dashboards/rider/reusalbe.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  bool _isOnline = false;
  int _activeOrdersCount = 0;
  List<Order> _availableJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initAblyListener();
  }

  // ─── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadDashboardData() async {
    try {
      final userId = _currentUserId;
      final jobs = await orderRepository.getAvailableJobs();
      final riderOrders = await orderRepository.getRiderOrders(userId);

      setState(() {
        _availableJobs = jobs;
        _activeOrdersCount = riderOrders.where(_isActiveOrder).length;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _initAblyListener() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    ablyService.initAbly(user.id);
    ablyService.subscribeToRiderChannel(
      user.id,
      onNewJob: _handleNewJob,
      onOrderUpdate: _handleOrderUpdate,
    );
  }

  void _handleNewJob(dynamic data) {
    final newOrder = Order.fromJson(Map<String, dynamic>.from(data));
    final alreadyExists = _availableJobs.any((o) => o.id == newOrder.id);
    if (!alreadyExists) {
      setState(() => _availableJobs.insert(0, newOrder));
    }
  }

  void _handleOrderUpdate(dynamic data) {
    final orderId = data['orderId'] as String?;
    final status = data['status'] as String?;
    if (orderId != null && status != 'READY_FOR_PICKUP') {
      setState(() => _availableJobs.removeWhere((o) => o.id == orderId));
    }
  }

  Future<void> _acceptJob(Order order) async {
    final userId = _currentUserId;
    try {
      await orderRepository.updateOrder(order.id, {
        'riderId': userId,
        'status': 'PICKING_UP',
      });
      setState(() {
        _availableJobs.removeWhere((o) => o.id == order.id);
        _activeOrdersCount++;
      });
      _showSnackBar('Job accepted! Go to Delivery tab to see details.');
    } catch (e) {
      _showSnackBar('Failed to accept job: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String get _currentUserId => context.read<AuthProvider>().user?.id ?? '';

  bool _isActiveOrder(Order o) =>
      o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OnlineStatusBanner(
              isOnline: _isOnline,
              onToggle: (value) => setState(() => _isOnline = value),
            ),
            const SizedBox(height: 16),
            const _EarningsRow(),
            const SizedBox(height: 16),
            _ActiveOrdersBadge(count: _activeOrdersCount),
            const SizedBox(height: 20),
            const _SectionLabel('Available Orders'),
            const SizedBox(height: 10),
            Expanded(
              child: _AvailableJobsList(
                isLoading: _isLoading,
                jobs: _availableJobs,
                onAccept: _acceptJob,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Online Status Banner ─────────────────────────────────────────────────

class _OnlineStatusBanner extends StatelessWidget {
  const _OnlineStatusBanner({required this.isOnline, required this.onToggle});

  final bool isOnline;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.primary : AppColors.lightMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: isOnline,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white24,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

// ─── Earnings Row ─────────────────────────────────────────────────────────

class _EarningsRow extends StatelessWidget {
  const _EarningsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: EarningsCard(title: 'Today', amount: '₦5,400'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: EarningsCard(title: 'Week', amount: '₦28,000'),
        ),
      ],
    );
  }
}

// ─── Active Orders Badge ──────────────────────────────────────────────────

class _ActiveOrdersBadge extends StatelessWidget {
  const _ActiveOrdersBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Active Orders: $count',
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}

// ─── Available Jobs List ──────────────────────────────────────────────────

class _AvailableJobsList extends StatelessWidget {
  const _AvailableJobsList({
    required this.isLoading,
    required this.jobs,
    required this.onAccept,
  });

  final bool isLoading;
  final List<Order> jobs;
  final ValueChanged<Order> onAccept;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (jobs.isEmpty)
      return const Center(child: Text('No jobs available right now.'));

    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, index) =>
          _JobListItem(job: jobs[index], onAccept: onAccept),
    );
  }
}

// ─── Job List Item ────────────────────────────────────────────────────────

class _JobListItem extends StatelessWidget {
  const _JobListItem({required this.job, required this.onAccept});

  final Order job;
  final ValueChanged<Order> onAccept;

  String get _shortId {
    final id = job.id;
    return 'Order #${id.length > 6 ? id.substring(id.length - 6) : id}';
  }

  String get _route {
    if (job.stores.isEmpty) return 'Unknown Route';
    return '${job.stores.first.name} → ${job.user?.name ?? 'Customer'}';
  }

  String get _pay => '₦${job.total.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return JobCard(
      id: _shortId,
      route: _route,
      pay: _pay,
      onAccept: () => onAccept(job),
    );
  }
}
