import 'package:flutter/material.dart';

class PasswordToggleIcon extends StatelessWidget {
  const PasswordToggleIcon({
    super.key,
    required this.isVisible,
    required this.onToggle,
  });

  final bool isVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        isVisible ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey,
      ),
    );
  }
}
