import 'package:flutter/material.dart';

class RiderDashboard extends StatelessWidget {
  const RiderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Panel', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Earnings Today', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('₦5,400', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Text('Available Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                Text('Go Online', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildJobCard('Order #8832', 'Hall 4 to Faculty', '₦500'),
            _buildJobCard('Order #8841', 'Hall 1 to Hall 8', '₦400'),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(String id, String route, String pay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delivery_dining, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(route, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(pay, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}
