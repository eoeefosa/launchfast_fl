import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CampusChowLoading extends StatelessWidget {
  final double size;
  final bool useLogo;

  const CampusChowLoading({
    super.key,
    this.size = 24.0,
    this.useLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final asset = useLogo ? 'assets/applogo.png' : 'assets/appicon.png';
    
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.fastfood_rounded,
            size: size,
            color: Theme.of(context).primaryColor,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.5),
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: 800.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(0.9, 0.9),
          duration: 800.ms,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}
