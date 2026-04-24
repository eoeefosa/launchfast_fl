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
    final scheme = Theme.of(context).colorScheme;
    final color = verified ? Colors.green : Colors.orangeAccent;

    return ProfileSettingsTile(
      icon: icon,
      title: title,
      iconColor: color,
      titleColor: verified ? null : color,
      subtitle: verified ? 'Account Verified' : 'Tap to complete verification',
      onTap: onTap,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          verified ? 'VERIFIED' : 'PENDING',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
