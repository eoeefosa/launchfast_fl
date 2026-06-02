import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackButton extends StatelessWidget {
  const BackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => GoRouter.of(context).pop(),
      icon: Icon(Icons.adaptive.arrow_back),
      style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
    );
  }
}
