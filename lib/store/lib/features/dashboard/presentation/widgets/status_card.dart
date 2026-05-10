import 'package:flutter/material.dart';

class DashboardStatusCard extends StatelessWidget {
  final bool isOpen;
  final bool toggling;
  final ValueChanged<bool> onToggle;

  const DashboardStatusCard({
    super.key,
    required this.isOpen,
    required this.toggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOpen ? Colors.green.shade600 : Colors.red.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOpen ? Icons.store : Icons.store_mall_directory_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'Store is OPEN' : 'Store is CLOSED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOpen ? 'Accepting orders right now' : 'Not accepting orders',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          toggling
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Switch(
                  value: isOpen,
                  onChanged: onToggle,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white.withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                ),
        ],
      ),
    );
  }
}
