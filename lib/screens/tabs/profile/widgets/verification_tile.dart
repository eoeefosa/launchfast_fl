import 'package:flutter/material.dart';
import 'settings_tile.dart';

class VerificationTile extends StatelessWidget {
  const VerificationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.verified,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool verified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsTile(
      icon: icon,
      title: title,
      iconColor: verified ? Colors.green : Colors.orange,
      titleColor: verified ? null : Colors.orange,
      subtitle: verified ? 'Account Verified' : 'Tap to complete verification',
      onTap: onTap,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: verified 
            ? Colors.green.withValues(alpha: 0.1) 
            : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          verified ? 'VERIFIED' : 'PENDING',
          style: TextStyle(
            color: verified ? Colors.green : Colors.orange,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
