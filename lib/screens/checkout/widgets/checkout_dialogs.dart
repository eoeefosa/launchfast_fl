import 'package:flutter/material.dart';

class CheckoutErrorDialog extends StatelessWidget {
  const CheckoutErrorDialog({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.red,
        size: 42,
      ),
      title: const Text(
        'Something went wrong',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ),
      ],
    );
  }
}
