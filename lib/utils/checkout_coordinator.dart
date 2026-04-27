import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coordinator for handling complex navigation flows during checkout.
/// This prevents navigation logic and BuildContext misuse from leaking into UI widgets.
abstract final class CheckoutCoordinator {
  static void handleInsufficientFunds(BuildContext context) {
    // Pop the dialog first to ensure the root navigator is clean
    Navigator.of(context, rootNavigator: true).pop();
    
    // Use .go() instead of .push() when navigating to a shell branch (like /profile).
    // .push() can cause 'keyReservation' assertion errors when navigating between 
    // top-level routes and shell routes.
    context.go('/profile');
  }
  
  static void returnToCheckout(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
