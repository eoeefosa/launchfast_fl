import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final store = authProvider.adminStore;

    if (!authProvider.isAdmin || store == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${store.name} Admin',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatBox('12', "Today's Orders"),
                const SizedBox(width: 12),
                _buildStatBox('₦14.5k', 'Revenue'),
              ],
            ),
            const SizedBox(height: 24),
            _buildAdminCard(
              context,
              icon: Icons.fastfood,
              title: 'Manage Menu',
              subtitle: 'Add, remove or edit items and prices',
              color: Colors.green,
              onTap: () => context.push('/admin/menu'),
            ),
            _buildAdminCard(
              context,
              icon: Icons.notifications,
              title: 'Live Orders',
              subtitle: 'View and manage incoming orders',
              color: Colors.orange,
              onTap: () {},
            ),
            _buildAdminCard(
              context,
              icon: Icons.directions_bike,
              title: 'Manage Riders',
              subtitle: 'Assign deliveries and track rider load',
              color: Colors.blue,
              onTap: () {},
            ),
            _buildAdminCard(
              context,
              icon: Icons.settings,
              title: 'Store Settings',
              subtitle: 'Update store info and hours',
              color: Colors.indigo,
              onTap: () {},
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                authProvider.logout();
                context.go('/profile');
              },
              child: const Text(
                'Logout from Admin',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
