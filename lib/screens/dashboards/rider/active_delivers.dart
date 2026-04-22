import 'package:flutter/material.dart';
import 'package:launchfast_fl/constants/app_colors.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  int step = 1;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// STEP VIEW
            if (step == 1) ...[
              const Text("Navigate to Restaurant"),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => setState(() => step = 2),
                child: const Text("Arrived at Restaurant"),
              )
            ],

            if (step == 2) ...[
              const Text("Pickup Order"),
              const Text("Items: Rice x2, Coke x1"),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => setState(() => step = 3),
                child: const Text("Order Picked Up"),
              )
            ],

            if (step == 3) ...[
              const Text("Navigate to Customer"),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => setState(() => step = 4),
                child: const Text("Arrived"),
              )
            ],

            if (step == 4) ...[
              const Text("Deliver to Customer"),
              const Text("Name: John"),
              const Text("Note: Behind Hall 5"),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => setState(() => step = 1),
                child: const Text("Order Delivered"),
              )
            ],
          ],
        ),
      ),
    );
  }
}