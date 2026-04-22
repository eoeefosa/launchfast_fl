import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // In a real app, this would come from an API
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'user',
    },
    {
      'id': '2',
      'name': 'Jane Store',
      'email': 'jane@store.com',
      'role': 'store_owner',
    },
    {'id': '3', 'name': 'Bob Rider', 'email': 'bob@rider.com', 'role': 'rider'},
    {
      'id': '4',
      'name': 'Admin User',
      'email': 'admin@lauchfast.com',
      'role': 'admin',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockUsers.length,
        itemBuilder: (context, index) {
          final user = _mockUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    Color roleColor = Colors.grey;
    if (user['role'] == 'admin') roleColor = Colors.red;
    if (user['role'] == 'store_owner') roleColor = Colors.green;
    if (user['role'] == 'rider') roleColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.1),
          child: Text(
            user['name'][0],
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user['role'].toString().toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (newRole) {
            setState(() {
              user['role'] = newRole;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Updated ${user['name']} to $newRole')),
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'user', child: Text('Set as User')),
            const PopupMenuItem(
              value: 'store_owner',
              child: Text('Set as Store Owner'),
            ),
            const PopupMenuItem(value: 'rider', child: Text('Set as Rider')),
            const PopupMenuItem(value: 'admin', child: Text('Set as Admin')),
          ],
        ),
      ),
    );
  }
}
