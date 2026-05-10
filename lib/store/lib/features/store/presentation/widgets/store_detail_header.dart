import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';

class StoreDetailHeader extends StatelessWidget {
  final Store store;
  final Color accentColor;

  const StoreDetailHeader({super.key, required this.store, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleRow(name: store.name, accentColor: accentColor),
            const SizedBox(height: 8),
            _Tagline(tagline: store.tagline),
            const SizedBox(height: 20),
            _StatsRow(store: store),
            const SizedBox(height: 12),
            const Divider(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String name;
  final Color accentColor;
  const _TitleRow({required this.name, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.favorite_outline_rounded, color: accentColor, size: 24),
        ),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  final String tagline;
  const _Tagline({required this.tagline});

  @override
  Widget build(BuildContext context) {
    return Text(tagline, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500));
  }
}

class _StatsRow extends StatelessWidget {
  final Store store;
  const _StatsRow({required this.store});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBadge(icon: Icons.star_rounded, text: store.rating.toString(), color: Colors.amber),
        const SizedBox(width: 12),
        _StatBadge(icon: Icons.access_time_filled_rounded, text: store.deliveryTime, color: Colors.blue),
        const SizedBox(width: 12),
        _StatBadge(icon: Icons.delivery_dining_rounded, text: 'Free', color: Colors.green),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatBadge({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
