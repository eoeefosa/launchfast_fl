import 'package:flutter/material.dart';
import '../../models/store.dart';

class StoreBanner extends StatelessWidget {
  final Store store;

  const StoreBanner({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.tagline,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfo(Icons.timer_outlined, store.deliveryTime),
                      const SizedBox(width: 12),
                      _buildInfo(
                        Icons.star,
                        '${store.rating}',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      _buildStatus(store.isOpen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text, {Color? color}) {
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Row(
        children: [
          Icon(icon, size: 14, color: color ?? scheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatus(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isOpen ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
  }
}
