import 'package:flutter/material.dart';
import 'package:launchfast_fl/constants/app_colors.dart';

class EarningsCard extends StatelessWidget {
  final String title;
  final String amount;

  const EarningsCard({super.key, required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final String id;
  final String route;
  final String pay;
  final VoidCallback onAccept;

  const JobCard({
    super.key,
    required this.id,
    required this.route,
    required this.pay,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(route),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pay,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 4),
            SizedBox(
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                ),
                onPressed: onAccept,
                child: const Text("Accept", style: TextStyle(fontSize: 12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}