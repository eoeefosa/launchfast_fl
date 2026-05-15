import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';

/// Bottom sheet that lets store staff verify a pickup order by either:
///   a) Scanning the customer's QR code (encodes the full order ID)
///   b) Typing / pasting the 8-character short code manually
///
/// Usage:
///   final orderId = await PickupScannerSheet.show(context, orders: _orders);
///   if (orderId != null) { // highlight / mark delivered }
class PickupScannerSheet extends StatefulWidget {
  /// All current orders — used for manual short-code lookup.
  final List<ScanOrder> orders;

  const PickupScannerSheet({super.key, required this.orders});

  static Future<String?> show(
    BuildContext context, {
    required List<ScanOrder> orders,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickupScannerSheet(orders: orders),
    );
  }

  @override
  State<PickupScannerSheet> createState() => _PickupScannerSheetState();
}

class _PickupScannerSheetState extends State<PickupScannerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  final MobileScannerController _scanCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  String? _searchError;
  bool _scanned = false; // prevent duplicate scan callbacks

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  // ── QR scan handler ──────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _scanned = true;
    HapticFeedback.mediumImpact();

    // Find the matching order (QR encodes full order ID)
    final match = widget.orders
        .cast<ScanOrder?>()
        .firstWhere((o) => o!.id == raw, orElse: () => null);

    if (match == null) {
      setState(() => _scanned = false);
      _showError('No matching order found for scanned code.');
      return;
    }

    Navigator.of(context).pop(match.id);
  }

  // ── Manual search handler ─────────────────────────────────────────────────

  void _onSearch() {
    final query = _searchCtrl.text.trim().toUpperCase();
    if (query.isEmpty) {
      setState(() => _searchError = 'Please enter an order code.');
      return;
    }

    // Match by last-8-chars short code OR full ID
    final match = widget.orders.cast<ScanOrder?>().firstWhere(
          (o) =>
              o!.shortCode == query ||
              o.id.toUpperCase() == query ||
              o.id.toUpperCase().endsWith(query),
          orElse: () => null,
        );

    if (match == null) {
      setState(() => _searchError = 'No order found with code "$query".');
      return;
    }

    setState(() => _searchError = null);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(match.id);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Pickup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Scan QR or enter order code',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tabs ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
                    text: 'Scan QR',
                  ),
                  Tab(
                    icon: Icon(Icons.search_rounded, size: 18),
                    text: 'Enter Code',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tab content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ScanTab(controller: _scanCtrl, onDetect: _onDetect),
                _SearchTab(
                  controller: _searchCtrl,
                  error: _searchError,
                  onSearch: _onSearch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan tab ─────────────────────────────────────────────────────────────────

class _ScanTab extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  const _ScanTab({required this.controller, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: onDetect,
                  ),
                  // Scan overlay frame
                  _ScannerOverlay(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Point camera at the customer\'s QR code',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerPainter(),
      child: const SizedBox(width: 220, height: 220),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 16.0; // corner radius
    const len = 36.0; // corner arm length

    final corners = [
      // top-left
      [Offset(r, 0), Offset(len, 0), Offset(0, r), Offset(0, len)],
      // top-right
      [
        Offset(size.width - len, 0),
        Offset(size.width - r, 0),
        Offset(size.width, r),
        Offset(size.width, len)
      ],
      // bottom-left
      [
        Offset(0, size.height - len),
        Offset(0, size.height - r),
        Offset(r, size.height),
        Offset(len, size.height)
      ],
      // bottom-right
      [
        Offset(size.width - len, size.height),
        Offset(size.width - r, size.height),
        Offset(size.width, size.height - r),
        Offset(size.width, size.height - len)
      ],
    ];

    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[2], c[3], paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Search tab ────────────────────────────────────────────────────────────────

class _SearchTab extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onSearch;

  const _SearchTab({
    required this.controller,
    required this.error,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Enter the 8-character order code\nshown on the customer\'s screen.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),

          // ── Code input ─────────────────────────────────────────────────
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. A1B2C3D4',
              hintStyle: TextStyle(
                fontSize: 22,
                letterSpacing: 4,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              errorText: error,
              prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'Verify & Confirm Pickup',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Tip ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The code is shown on the customer\'s Orders screen and works even without internet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lightweight model passed into the sheet ───────────────────────────────────

class ScanOrder {
  final String id;

  const ScanOrder(this.id);

  String get shortCode => id.length >= 8
      ? id.substring(id.length - 8).toUpperCase()
      : id.toUpperCase();
}
