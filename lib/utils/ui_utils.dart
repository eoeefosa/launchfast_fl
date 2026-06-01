import 'package:flutter/material.dart';

class UIUtils {
  /// Optimizes Cloudinary URLs by injecting f_auto (format), q_auto (quality), 
  /// and a maximum width.
  static String optimizeCloudinaryUrl(String url, {int width = 1200}) {
    if (url.isEmpty || !url.contains('res.cloudinary.com')) return url;
    
    // Check if it's an upload URL and doesn't already have transformations
    if (url.contains('/upload/') && !url.contains('/upload/f_auto')) {
      final parts = url.split('/upload/');
      if (parts.length == 2) {
        return '${parts[0]}/upload/f_auto,q_auto,w_$width/${parts[1]}';
      }
    }
    return url;
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
