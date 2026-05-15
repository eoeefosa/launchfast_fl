import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_colors.dart';

/// Shown on the customer's Orders screen when:
///   - deliveryType == 'pickup' (or 'store_pickup')
///   - status == readyForPickup
///
/// The QR encodes the raw order ID, which the store scans offline.
/// The short code is also shown so staff can search manually.
class PickupQrCard extends StatelessWidget {
  final String orderId;

  const PickupQrCard({super.key, required this.orderId});

  // Last 8 characters, uppercase — human-readable short code
  String get _shortCode => orderId.length >= 8
      ? orderId.substring(orderId.length - 8).toUpperCase()
      : orderId.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final qrFg = isDark ? Colors.white : const Color(0xFF0D0D1A);
    final qrBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // ── Header banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(height: 4),
                  const Text(
                    'READY FOR PICKUP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Show this code at the counter',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ── QR Code ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // QR with subtle frame
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: qrBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: QrImageView(
                      data: orderId,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: qrBg,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: qrFg,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: qrFg,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Short code + copy ─────────────────────────────────
                  Text(
                    'Order Code',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _shortCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Order code copied!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _shortCode,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 4,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Tip ───────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'Works offline — no internet needed at pickup',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }
}
