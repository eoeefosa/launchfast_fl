import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launchfast_fl/constants/app_colors.dart';
import 'package:launchfast_fl/providers/auth_provider.dart';
import 'package:launchfast_fl/services/ably_service.dart';
import 'package:launchfast_fl/repositories/order_repository.dart';
import 'package:launchfast_fl/models/order.dart';
import 'package:launchfast_fl/screens/dashboards/rider/reusalbe.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  bool isOnline = false;
  int activeOrdersCount = 0;
  List<Order> availableJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initAbly();
  }

  Future<void> _loadDashboardData() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final jobs = await orderRepository.getAvailableJobs();
      final active = await orderRepository.getRiderOrders(auth.user?.id ?? "");
      
      setState(() {
        availableJobs = jobs;
        activeOrdersCount = active.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _initAbly() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.id != null) {
      ablyService.initAbly(auth.user!.id);
      ablyService.subscribeToRiderChannel(
        auth.user!.id,
        onNewJob: (data) {
          final newOrder = Order.fromJson(Map<String, dynamic>.from(data));
          setState(() {
            if (!availableJobs.any((o) => o.id == newOrder.id)) {
              availableJobs.insert(0, newOrder);
            }
          });
        },
        onOrderUpdate: (data) {
          final orderId = data['orderId'];
          final status = data['status'];
          if (status != 'READY_FOR_PICKUP') {
            setState(() {
              availableJobs.removeWhere((o) => o.id == orderId);
            });
          }
        },
      );
    }
  }

  Future<void> _acceptJob(Order order) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await orderRepository.updateOrder(order.id, {
        'riderId': auth.user!.id,
        'status': 'PICKING_UP',
      });
      
      setState(() {
        availableJobs.removeWhere((o) => o.id == order.id);
        activeOrdersCount++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job accepted! Go to Delivery tab to see details.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to accept job: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Rider Dashboard"),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// STATUS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.primary : AppColors.lightMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOnline ? "ONLINE" : "OFFLINE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: isOnline,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white24,
                    onChanged: (v) => setState(() => isOnline = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// EARNINGS
            Row(
              children: const [
                Expanded(
                  child: EarningsCard(title: "Today", amount: "₦5,400"),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: EarningsCard(title: "Week", amount: "₦28,000"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ACTIVE ORDERS
            Text("Active Orders: $activeOrdersCount"),

            const SizedBox(height: 20),

            /// AVAILABLE ORDERS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Available Orders",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (availableJobs.isEmpty)
              const Center(child: Text("No jobs available right now."))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availableJobs.length,
                  itemBuilder: (context, index) {
                    final job = availableJobs[index];
                    return JobCard(
                      id: "Order #${job.id.length > 6 ? job.id.substring(job.id.length - 6) : job.id}",
                      route: job.stores.isNotEmpty 
                        ? "${job.stores.first.name} → ${job.user?.name ?? 'Customer'}"
                        : "Unknown Route",
                      pay: "₦${job.total.toStringAsFixed(0)}",
                      onAccept: () => _acceptJob(job),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
