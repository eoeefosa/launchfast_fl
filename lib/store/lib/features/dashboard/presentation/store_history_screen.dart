import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'widgets/pickup_scanner_sheet.dart';
import 'widgets/order_card.dart';
import 'widgets/order_card_skeleton.dart';
import 'widgets/order_screen_component.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kFilters = <OrderStatus?>[
  null,
  OrderStatus.pending,
  OrderStatus.preparing,
  OrderStatus.readyForPickup,
  OrderStatus.delivered,
  OrderStatus.cancelled,
];

// ─────────────────────────────────────────────────────────────────────────────
// StoreHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────

class StoreHistoryScreen extends StatefulWidget {
  const StoreHistoryScreen({super.key});

  @override
  State<StoreHistoryScreen> createState() => _StoreHistoryScreenState();
}

class _StoreHistoryScreenState extends State<StoreHistoryScreen>
    with TickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _groupByDay = true;

  late final TabController _tabController;
  late final TextEditingController _searchController;

  OrderStatus? get _activeFilter => _kFilters[_tabController.index];

  List<Order> get _pastOrders {
    final now = DateTime.now();
    return _orders.where((o) {
      if (o.date.isEmpty) return false;
      try {
        final d = DateTime.parse(o.date).toLocal();
        return !(d.year == now.year &&
            d.month == now.month &&
            d.day == now.day);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Order> get _filtered {
    var list = _pastOrders;

    final filter = _activeFilter;
    if (filter != null) {
      list = list.where((o) => o.status == filter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) {
        final shortId = _shortId(o.id).toLowerCase();
        return o.id.toLowerCase().contains(q) ||
            shortId.contains(q) ||
            (o.user?.name.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  Map<String, List<Order>> get _groupedByDay {
    final map = <String, List<Order>>{};
    for (final o in _filtered) {
      try {
        final d = DateTime.parse(o.date).toLocal();
        final key = DateFormat('yyyy-MM-dd').format(d);
        map.putIfAbsent(key, () => []).add(o);
      } catch (_) {}
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kFilters.length, vsync: this)
      ..addListener(_onTabChanged);
    _searchController = TextEditingController();
    _loadOrders(showSkeleton: true);
    _subscribeAbly();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  Future<void> _loadOrders({bool showSkeleton = false}) async {
    if (!mounted) return;
    if (showSkeleton) setState(() => _isLoading = true);
    try {
      final orders = await context.read<StoreProvider>().fetchStoreOrders();
      orders.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() => _orders = orders);
    } catch (e, stack) {
      debugPrint('[StoreHistoryScreen] _loadOrders: $e\n$stack');
      _showSnackBar('Failed to load orders', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(
    String orderId,
    OrderStatus newStatus, {
    String? rejectionReason,
  }) async {
    try {
      await context.read<StoreProvider>().updateOrderStatus(
        orderId,
        newStatus.backendName,
        rejectionReason: rejectionReason,
      );
      await _loadOrders();
      _showSnackBar('Order updated to ${newStatus.displayLabel}');
    } catch (e, stack) {
      debugPrint('[StoreHistoryScreen] _updateStatus: $e\n$stack');
      _showSnackBar('Failed to update order', isError: true);
    }
  }

  void _subscribeAbly() {
    ablyService.addOrderListener((orderId, status) => _loadOrders());
  }

  Future<void> _openPickupScanner() async {
    if (!mounted) return;
    final scanOrders = _orders.map((o) => ScanOrder(o.id)).toList();
    final confirmedId = await PickupScannerSheet.show(context, orders: scanOrders);
    if (confirmedId == null || !mounted) return;

    final matched = _orders.cast<Order?>().firstWhere(
      (o) => o!.id == confirmedId,
      orElse: () => null,
    );
    if (matched == null) return;

    if (!_isPickupDeliveryType(matched.deliveryType)) {
      _showSnackBar('This order is not a pickup order.', isWarning: true);
      return;
    }
    if (matched.status != OrderStatus.readyForPickup) {
      _showSnackBar('Order is not ready for pickup.', isWarning: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => PickupConfirmDialog(
        shortCode: _shortId(confirmedId).toUpperCase(),
        customerName: matched.user?.name ?? 'Customer',
      ),
    );
    if (confirmed == true && mounted) {
      await _updateStatus(confirmedId, OrderStatus.delivered);
    }
  }

  // ── PDF export ────────────────────────────────────────────────────────────

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportSheet(
        orders: _pastOrders,
        storeName: context.read<StoreProvider>().ownedStore?.name ?? 'Store',
        onExport: _exportPdf,
      ),
    );
  }

  Future<void> _exportPdf(List<Order> orders, String label, String storeName) async {
    if (orders.isEmpty) {
      _showSnackBar('No orders in this period', isError: false);
      return;
    }

    try {
      final bytes = await _buildPdf(orders, label, storeName);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${storeName.replaceAll(' ', '_')}_$label.pdf',
      );
      await file.writeAsBytes(bytes);

      // Try native print first, fall back to share
      await Printing.sharePdf(bytes: bytes, filename: file.path.split('/').last);
    } catch (e) {
      _showSnackBar('Failed to generate PDF: $e', isError: true);
    }
  }

  Future<Uint8List> _buildPdf(
    List<Order> orders,
    String label,
    String storeName,
  ) async {
    final pdf = pw.Document();

    // Group orders by day for the PDF
    final grouped = <String, List<Order>>{};
    for (final o in orders) {
      try {
        final d = DateTime.parse(o.date).toLocal();
        final key = DateFormat('yyyy-MM-dd').format(d);
        grouped.putIfAbsent(key, () => []).add(o);
      } catch (_) {}
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final totalRevenue = orders.fold<double>(0, (s, o) => s + o.total);
    final deliveredCount =
        orders.where((o) => o.status == OrderStatus.delivered).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _pdfHeader(storeName, label),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          // Summary box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF3EC),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFFF6B2C), width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Total Orders', '${orders.length}'),
                _summaryItem('Delivered', '$deliveredCount'),
                _summaryItem('Total Revenue', '₦${_fmt(totalRevenue)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Per-day sections
          for (final day in sortedDays) ...[
            _pdfDayHeader(day, grouped[day]!),
            pw.SizedBox(height: 6),
            _pdfOrdersTable(grouped[day]!),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfHeader(String storeName, String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              storeName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFFFF6B2C),
              ),
            ),
            pw.Text(
              'Order Report — $label',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Divider(color: const PdfColor.fromInt(0xFFFF6B2C), thickness: 1.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _pdfDayHeader(String day, List<Order> orders) {
    final date = DateTime.parse(day);
    final label = DateFormat('EEEE, dd MMMM yyyy').format(date);
    final dayTotal = orders.fold<double>(0, (s, o) => s + o.total);
    return pw.Container(
      color: const PdfColor.fromInt(0xFFF5F5F5),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.Text(
            '${orders.length} order${orders.length == 1 ? '' : 's'} · ₦${_fmt(dayTotal)}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfOrdersTable(List<Order> orders) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['Order ID', 'Customer', 'Items', 'Type', 'Status', 'Total']
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ),
              )
              .toList(),
        ),
        // Data rows
        for (final o in orders)
          pw.TableRow(
            children: [
              _cell('#${_shortId(o.id).toUpperCase()}'),
              _cell(o.resolvedCustomerName),
              _cell(o.items.map((i) => '${i.quantity}x ${i.menuItem.name}').join(', ')),
              _cell(o.deliveryType),
              _cell(o.status.displayLabel),
              _cell('₦${_fmt(o.total)}'),
            ],
          ),
      ],
    );
  }

  pw.Widget _cell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 8),
            maxLines: 2,
            overflow: pw.TextOverflow.clip),
      );

  pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
              color: const PdfColor.fromInt(0xFFFF6B2C),
            )),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  static String _fmt(double v) =>
      NumberFormat('#,##0', 'en_US').format(v.toInt());

  static bool _isPickupDeliveryType(String deliveryType) {
    final t = deliveryType.toLowerCase();
    return t == 'pickup' || t == 'store_pickup';
  }

  static String _shortId(String id) =>
      id.length >= 8 ? id.substring(id.length - 8) : id;

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    final color = isError
        ? Colors.red.shade700
        : isWarning
            ? Colors.orange.shade700
            : Colors.green.shade700;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Order History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Verify Pickup',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            onPressed: _openPickupScanner,
          ),
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: _showExportDialog,
          ),
          IconButton(
            tooltip: 'Toggle view',
            icon: Icon(
              _groupByDay ? Icons.view_list_rounded : Icons.calendar_view_day_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _groupByDay = !_groupByDay),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _kFilters
              .map((f) => Tab(text: f == null ? 'All' : f.displayLabel))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          OrderSearchBar(
            controller: _searchController,
            query: _searchQuery,
            bg: bg,
            surface: surface,
            muted: muted,
            border: border,
            onChanged: (v) => setState(() => _searchQuery = v),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Expanded(
            child: _isLoading
                ? OrderListSkeleton(isDark: isDark)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadOrders,
                    child: _filtered.isEmpty
                        ? OrderEmptyState(muted: muted)
                        : _groupByDay
                            ? _DayGroupedList(
                                grouped: _groupedByDay,
                                textColor: textColor,
                                muted: muted,
                                surface: surface,
                                border: border,
                                bg: bg,
                                onUpdateStatus: _updateStatus,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => OrderCard(
                                  order: _filtered[i],
                                  isUpdating: false,
                                  textColor: textColor,
                                  muted: muted,
                                  surface: surface,
                                  border: border,
                                  onUpdateStatus: _updateStatus,
                                ),
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day-grouped list
// ─────────────────────────────────────────────────────────────────────────────

class _DayGroupedList extends StatefulWidget {
  const _DayGroupedList({
    required this.grouped,
    required this.textColor,
    required this.muted,
    required this.surface,
    required this.border,
    required this.bg,
    required this.onUpdateStatus,
  });

  final Map<String, List<Order>> grouped;
  final Color textColor;
  final Color muted;
  final Color surface;
  final Color border;
  final Color bg;
  final Future<void> Function(String, OrderStatus, {String? rejectionReason}) onUpdateStatus;

  @override
  State<_DayGroupedList> createState() => _DayGroupedListState();
}

class _DayGroupedListState extends State<_DayGroupedList> {
  final Set<String> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final days = widget.grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final orders = widget.grouped[day]!;
        final isCollapsed = _collapsed.contains(day);
        final dayDate = DateTime.parse(day);
        final isToday = _isToday(dayDate);
        final isYesterday = _isYesterday(dayDate);
        final label = isToday
            ? 'Today'
            : isYesterday
                ? 'Yesterday'
                : DateFormat('EEE, dd MMM yyyy').format(dayDate);

        final dayTotal = orders.fold<double>(0, (s, o) => s + o.total);
        final deliveredCount =
            orders.where((o) => o.status == OrderStatus.delivered).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header / overview card
            GestureDetector(
              onTap: () => setState(() {
                if (isCollapsed) {
                  _collapsed.remove(day);
                } else {
                  _collapsed.add(day);
                }
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    // Date icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${dayDate.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: widget.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${orders.length} order${orders.length == 1 ? '' : 's'}'
                            ' · $deliveredCount delivered',
                            style: TextStyle(color: widget.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${NumberFormat('#,##0').format(dayTotal.toInt())}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'total',
                          style: TextStyle(color: widget.muted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isCollapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Order cards
            if (!isCollapsed) ...[
              ...orders.map(
                (o) => OrderCard(
                  order: o,
                  isUpdating: false,
                  textColor: widget.textColor,
                  muted: widget.muted,
                  surface: widget.surface,
                  border: widget.border,
                  onUpdateStatus: widget.onUpdateStatus,
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 6),
          ],
        );
      },
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static bool _isYesterday(DateTime d) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({
    required this.orders,
    required this.storeName,
    required this.onExport,
  });

  final List<Order> orders;
  final String storeName;
  final Future<void> Function(List<Order> orders, String label, String storeName) onExport;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _exporting = false;
  DateTime? _customFrom;
  DateTime? _customTo;

  List<Order> _filterByRange(DateTime from, DateTime to) {
    return widget.orders.where((o) {
      try {
        final d = DateTime.parse(o.date).toLocal();
        return !d.isBefore(from) && !d.isAfter(to);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  Future<void> _run(List<Order> orders, String label) async {
    setState(() => _exporting = true);
    try {
      await widget.onExport(orders, label, widget.storeName);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Preset ranges
    final yesterday = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    final presets = [
      (
        label: 'Yesterday',
        from: yesterday,
        to: yesterday.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
        icon: Icons.today_rounded,
      ),
      (
        label: 'This Week',
        from: weekStart,
        to: now,
        icon: Icons.date_range_rounded,
      ),
      (
        label: 'Last Week',
        from: lastWeekStart,
        to: weekStart.subtract(const Duration(seconds: 1)),
        icon: Icons.date_range_outlined,
      ),
      (
        label: 'This Month',
        from: monthStart,
        to: now,
        icon: Icons.calendar_month_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Export PDF Report',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a period to generate the order report',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (_exporting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            // Presets
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: presets.map((p) {
                final count = _filterByRange(p.from, p.to).length;
                return _PresetChip(
                  label: p.label,
                  subtitle: '$count orders',
                  icon: p.icon,
                  onTap: count == 0
                      ? null
                      : () => _run(_filterByRange(p.from, p.to), p.label),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom range
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Custom range',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: _customFrom == null
                        ? 'From'
                        : _fmtDate(_customFrom!),
                    icon: Icons.calendar_today_rounded,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _customFrom ?? now.subtract(const Duration(days: 7)),
                        firstDate: DateTime(2020),
                        lastDate: now,
                      );
                      if (d != null) setState(() => _customFrom = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateButton(
                    label: _customTo == null ? 'To' : _fmtDate(_customTo!),
                    icon: Icons.event_rounded,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _customTo ?? now,
                        firstDate: DateTime(2020),
                        lastDate: now,
                      );
                      if (d != null) setState(() => _customTo = d);
                    },
                  ),
                ),
              ],
            ),
            if (_customFrom != null && _customTo != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(
                    'Export ${_fmtDate(_customFrom!)} – ${_fmtDate(_customTo!)}',
                  ),
                  onPressed: () {
                    final to = _customTo!
                        .add(const Duration(hours: 23, minutes: 59, seconds: 59));
                    final orders = _filterByRange(_customFrom!, to);
                    final label =
                        '${_fmtDate(_customFrom!)}_to_${_fmtDate(_customTo!)}';
                    _run(orders, label);
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: enabled ? AppColors.primary : Colors.grey),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: enabled ? AppColors.primary : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled
                        ? AppColors.primary.withValues(alpha: 0.7)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
