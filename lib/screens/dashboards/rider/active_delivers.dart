import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launchfast_fl/constants/app_colors.dart';
import 'package:launchfast_fl/providers/auth_provider.dart';
import 'package:launchfast_fl/repositories/order_repository.dart';
import 'package:launchfast_fl/models/order.dart';
import 'package:launchfast_fl/services/ably_service.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  Order? _activeOrder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveDelivery();
    _initAblyListener();
  }

  // ─── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadActiveDelivery() async {
    try {
      final userId = _currentUserId;
      final orders = await orderRepository.getRiderOrders(userId);
      final active = orders.where(_isActiveOrder).toList();

      setState(() {
        _activeOrder = active.isNotEmpty ? active.first : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _initAblyListener() {
    if (_currentUserId.isEmpty) return;

    ablyService.addOrderListener((orderId, status) {
      if (_activeOrder?.id == orderId) {
        setState(() => _activeOrder = _activeOrder!.copyWith(status: status));
      } else if (_isIncomingAssignment(status)) {
        _loadActiveDelivery();
      }
    });
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    if (_activeOrder == null) return;

    try {
      final updated = await orderRepository.updateOrderStatus(
        _activeOrder!.id,
        newStatus.name.toUpperCase(),
      );
      setState(() {
        _activeOrder = newStatus == OrderStatus.delivered ? null : updated;
      });
    } catch (e) {
      _showError("Failed to update status: $e");
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String get _currentUserId {
    return context.read<AuthProvider>().user?.id ?? '';
  }

  bool _isActiveOrder(Order o) =>
      o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled;

  bool _isIncomingAssignment(OrderStatus status) =>
      status == OrderStatus.pickingUp || status == OrderStatus.readyForPickup;

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Active Delivery'),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_activeOrder == null) {
      return const Center(child: Text('No active delivery right now.'));
    }
    return _ActiveDeliveryContent(
      order: _activeOrder!,
      onUpdateStatus: _updateStatus,
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────

class _ActiveDeliveryContent extends StatelessWidget {
  const _ActiveDeliveryContent({
    required this.order,
    required this.onUpdateStatus,
  });

  final Order order;
  final ValueChanged<OrderStatus> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderSummaryCard(order: order),
          const SizedBox(height: 24),
          _DeliveryStepActions(
            status: order.status,
            onUpdateStatus: onUpdateStatus,
          ),
        ],
      ),
    );
  }
}

// ─── Order Summary Card ────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final Order order;

  String get _shortId => order.id.substring(order.id.length - 6);
  String get _statusLabel =>
      order.status.name.toUpperCase().replaceAll('_', ' ');
  String get _restaurantName =>
      order.stores.isNotEmpty ? order.stores.first.name : 'Unknown';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _OrderHeader(shortId: _shortId, statusLabel: _statusLabel),
            const Divider(height: 24),
            _OrderInfoRow(
              icon: Icons.store,
              label: 'Restaurant',
              value: _restaurantName,
            ),
            const SizedBox(height: 12),
            _OrderInfoRow(
              icon: Icons.person,
              label: 'Customer',
              value: order.user?.name ?? 'Unknown',
            ),
            const SizedBox(height: 12),
            _OrderInfoRow(
              icon: Icons.location_on,
              label: 'Delivery to',
              value: order.user?.phone ?? 'No phone',
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.shortId, required this.statusLabel});

  final String shortId;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order #$shortId',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        _StatusBadge(label: statusLabel),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.lightMuted),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  const TextStyle(color: AppColors.lightMuted, fontSize: 12),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

// ─── Step Actions ──────────────────────────────────────────────────────────

class _DeliveryStepActions extends StatelessWidget {
  const _DeliveryStepActions({
    required this.status,
    required this.onUpdateStatus,
  });

  final OrderStatus status;
  final ValueChanged<OrderStatus> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      OrderStatus.pickingUp => _DeliveryStep(
          heading: 'Navigate to Restaurant',
          buttonLabel: 'Arrived at Restaurant',
          onPressed: () => onUpdateStatus(OrderStatus.readyForPickup),
        ),
      OrderStatus.readyForPickup => _DeliveryStep(
          heading: 'Pickup Order',
          subtitle: 'Verify items with the restaurant.',
          buttonLabel: 'Order Picked Up',
          onPressed: () => onUpdateStatus(OrderStatus.onTheWay),
        ),
      OrderStatus.onTheWay => _DeliveryStep(
          heading: 'Navigate to Customer',
          buttonLabel: 'Mark as Delivered',
          onPressed: () => onUpdateStatus(OrderStatus.delivered),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _DeliveryStep extends StatelessWidget {
  const _DeliveryStep({
    required this.heading,
    required this.buttonLabel,
    required this.onPressed,
    this.subtitle,
  });

  final String heading;
  final String? subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          heading,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}