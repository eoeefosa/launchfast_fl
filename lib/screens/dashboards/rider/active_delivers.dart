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
  Order? activeOrder;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveDelivery();
    _initAbly();
  }

  Future<void> _loadActiveDelivery() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final orders = await orderRepository.getRiderOrders(auth.user?.id ?? "");
      
      // Filter for orders that are not delivered or cancelled
      final active = orders.where((o) => 
        o.status != OrderStatus.delivered && 
        o.status != OrderStatus.cancelled
      ).toList();

      setState(() {
        if (active.isNotEmpty) {
          activeOrder = active.first;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _initAbly() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.id != null) {
      ablyService.addOrderListener((orderId, status) {
        if (activeOrder?.id == orderId) {
          setState(() {
            activeOrder = activeOrder!.copyWith(status: status);
          });
        } else if (status == OrderStatus.pickingUp || status == OrderStatus.readyForPickup) {
          // Might be a new assignment
          _loadActiveDelivery();
        }
      });
    }
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    if (activeOrder == null) return;
    
    try {
      final updated = await orderRepository.updateOrderStatus(activeOrder!.id, newStatus.name.toUpperCase());
      setState(() {
        activeOrder = updated;
        if (newStatus == OrderStatus.delivered) {
          activeOrder = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Active Delivery"),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : activeOrder == null 
          ? const Center(child: Text("No active delivery right now."))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.lightBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Order #${activeOrder!.id.substring(activeOrder!.id.length - 6)}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(activeOrder!.status.name.toUpperCase().replaceAll('_', ' '),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.store, "Restaurant", activeOrder!.stores.isNotEmpty ? activeOrder!.stores.first.name : "Unknown"),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, "Customer", activeOrder!.user?.name ?? "Unknown"),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, "Delivery to", activeOrder!.user?.phone ?? "No phone"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// STEP VIEW
            if (activeOrder!.status == OrderStatus.pickingUp) ...[
              const Center(child: Text("Navigate to Restaurant", style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _updateStatus(OrderStatus.readyForPickup), // Or a custom status like 'ARRIVED_AT_STORE'
                  child: const Text("Arrived at Restaurant"),
                ),
              )
            ],

            if (activeOrder!.status == OrderStatus.readyForPickup) ...[
              const Center(child: Text("Pickup Order", style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              const Center(child: Text("Verify items with the restaurant.")),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _updateStatus(OrderStatus.onTheWay),
                  child: const Text("Order Picked Up"),
                ),
              )
            ],

            if (activeOrder!.status == OrderStatus.onTheWay) ...[
              const Center(child: Text("Navigate to Customer", style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _updateStatus(OrderStatus.delivered),
                  child: const Text("Mark as Delivered"),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.lightMuted),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.lightMuted, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}