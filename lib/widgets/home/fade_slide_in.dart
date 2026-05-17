import 'package:flutter/material.dart';

/// Animates its [child] from slightly below its final position to its natural
/// position while fading in. Used for the store section on initial render.
///
/// Implemented with [TweenAnimationBuilder] rather than flutter_animate for
/// precision: it runs exactly once and does not restart on rebuild.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      // child is passed through so it is not rebuilt on each animation tick.
      child: child,
      builder: (_, value, builtChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: builtChild,
        ),
      ),
    );
  }
}
