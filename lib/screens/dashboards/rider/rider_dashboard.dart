import 'package:flutter/material.dart';
import 'package:launchfast_fl/constants/app_colors.dart';
import 'package:launchfast_fl/screens/dashboards/rider/reusalbe.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  bool isOnline = false;
  int activeOrders = 1;

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
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// EARNINGS
            Row(
              children: const [
                Expanded(child: EarningsCard(title: "Today", amount: "₦5,400")),
                SizedBox(width: 10),
                Expanded(child: EarningsCard(title: "Week", amount: "₦28,000")),
              ],
            ),

            const SizedBox(height: 16),

            /// ACTIVE ORDERS
            Text("Active Orders: $activeOrders"),

            const SizedBox(height: 20),

            /// AVAILABLE ORDERS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Available Orders",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            JobCard(
              id: "Order #8832",
              route: "Hall 4 → Faculty",
              pay: "₦500",
              onAccept: () {
                setState(() => activeOrders++);
              },
            ),
          ],
        ),
      ),
    );
  }
}