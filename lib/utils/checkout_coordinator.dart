import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coordinator for handling complex navigation flows during checkout.
/// This prevents navigation logic and BuildContext misuse from leaking into UI widgets.
abstract final class CheckoutCoordinator {
  static void handleInsufficientFunds(BuildContext context) {
    // Pop the dialog
    Navigator.of(context, rootNavigator: true).pop();
    // Navigate to profile for top-up
    context.push('/profile');
  }
  
  static void returnToCheckout(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
