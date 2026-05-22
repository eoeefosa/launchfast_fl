import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:campuschow/store/lib/core/theme/app_colors.dart';
import 'package:campuschow/store/lib/features/orders/data/order_model.dart';
import 'package:campuschow/store/lib/features/store/presentation/store_provider.dart';
import 'package:campuschow/store/lib/core/services/ably_service.dart';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'widgets/pickup_scanner_sheet.dart';
import 'widgets/order_card.dart';
import 'widgets/order_screen_component.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kFilters = <OrderStatus?>[
  null, // All
  OrderStatus.pending,
  OrderStatus.preparing,
  OrderStatus.readyForPickup,
  OrderStatus.delivered,
  OrderStatus.cancelled,
];

// ─────────────────────────────────────────────────────────────────────────────
// StoreOrdersScreen
// ─────────────────────────────────────────────────────────────────────────────

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  List<Order> _orders = [];
  final Set<String> _updatingOrderIds = {};
  bool _isLoading = true;
  bool _hasNewOrder = false;
  String _searchQuery = '';
  String _deliveryTypeFilter = 'all'; // 'all', 'delivery', 'pickup'
  bool _isSelectionMode = false;
  final Set<String> _selectedOrderIds = {};
  final Set<String> _dismissedUnattendedOrderIds = {};
  final Set<String> _knownOrderIds = {};
  Timer? _orderPollTimer;
  bool _hasLoadedOrders = false;

  // ── Controllers ────────────────────────────────────────────────────────────
  late final TabController _tabController;
  late final TextEditingController _searchController;
  late final AnimationController _badgePulse;
  late final Animation<double> _badgeScale;

  // ── Unattended Notification Reminders ──────────────────────────────────────
  DateTime? _lastNotificationTime;
  Timer? _unattendedTimer;
  AudioPlayer? _reminderAudioPlayer;

  // ── Derived ────────────────────────────────────────────────────────────────
  OrderStatus? get _activeFilter => _kFilters[_tabController.index];

  List<Order> get _filtered {
    final now = DateTime.now();
    var list = _orders.where((o) {
      if (o.date.isEmpty) return false;
      try {
        final d = DateTime.parse(o.date).toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();

    final filter = _activeFilter;
    if (filter != null) {
      list = list.where((o) => o.status == filter).toList();
    }

    if (_deliveryTypeFilter == 'pickup') {
      list = list.where((o) => _isPickupDeliveryType(o.deliveryType)).toList();
    } else if (_deliveryTypeFilter == 'delivery') {
      list = list.where((o) => !_isPickupDeliveryType(o.deliveryType)).toList();
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

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _kFilters.length, vsync: this)
      ..addListener(_onTabChanged);

    _searchController = TextEditingController();

    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _badgeScale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _badgePulse, curve: Curves.easeInOut));

    _initAudioPlayer();
    _loadOrders();
    _subscribeAbly();
    _startOrderPolling();
    _startUnattendedTimer();
  }

  @override
  void dispose() {
    _orderPollTimer?.cancel();
    _unattendedTimer?.cancel();
    _reminderAudioPlayer?.dispose();
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
    _badgePulse.dispose();
    super.dispose();
  }

  // ── Tab listener ───────────────────────────────────────────────────────────

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _rejectPastOrders(List<Order> orders) async {
    final today = DateTime.now();
    final pastUnattended = orders.where((o) {
      if (o.date.isEmpty) return false;
      try {
        final od = DateTime.parse(o.date).toLocal();
        final isPreviousDay =
            od.year < today.year ||
            (od.year == today.year && od.month < today.month) ||
            (od.year == today.year &&
                od.month == today.month &&
                od.day < today.day);

        final isUnattended =
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.accepted ||
            o.status == OrderStatus.preparing;

        return isPreviousDay && isUnattended;
      } catch (_) {
        return false;
      }
    }).toList();

    if (pastUnattended.isEmpty) return;

    for (final o in pastUnattended) {
      try {
        await context.read<StoreProvider>().updateOrderStatus(
          o.id,
          OrderStatus.cancelled.backendName,
        );
      } catch (e) {
        debugPrint('Failed to auto-reject past order ${o.id}: $e');
      }
    }
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final storeProvider = context.read<StoreProvider>();
    try {
      var orders = await storeProvider.fetchStoreOrders();
      await _rejectPastOrders(orders);
      orders = await storeProvider.fetchStoreOrders();
      orders.sort((a, b) => b.date.compareTo(a.date));
      _notifyForNewPendingOrders(orders);
      if (mounted) {
        setState(() => _orders = orders);
        // Run initial unattended reminder check
        _checkUnattendedOrdersAndNotify();
      }
    } catch (e, stack) {
      debugPrint('[StoreOrdersScreen] _loadOrders: $e\n$stack');
      _showSnackBar('Failed to load orders', isError: true);
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startOrderPolling() {
    _orderPollTimer?.cancel();
    _orderPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadOrders(showLoading: false);
      }
    });
  }

  void _notifyForNewPendingOrders(List<Order> orders) {
    final incomingIds = orders.map((order) => order.id).toSet();

    if (!_hasLoadedOrders) {
      _knownOrderIds
        ..clear()
        ..addAll(incomingIds);
      _hasLoadedOrders = true;
      return;
    }

    for (final order in orders) {
      if (order.status != OrderStatus.pending) continue;
      if (_knownOrderIds.contains(order.id)) continue;

      _knownOrderIds.add(order.id);
      _playReminderSound();
      notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'New Order Received!',
        body: 'You have a new pending order. Tap to view.',
        payload: 'order_${order.id}',
        channelId: kOrderChannelId,
      );
      if (mounted) {
        setState(() => _hasNewOrder = true);
      }
    }

    _knownOrderIds
      ..removeWhere((id) => !incomingIds.contains(id))
      ..addAll(incomingIds);
  }

  Future<void> _updateStatus(String orderId, OrderStatus newStatus) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    final previousOrder = _orders[index];

    setState(() {
      _updatingOrderIds.add(orderId);
      _orders[index] = previousOrder.copyWith(status: newStatus);
    });

    try {
      await context.read<StoreProvider>().updateOrderStatus(
        orderId,
        newStatus.backendName,
      );
      if (newStatus == OrderStatus.priceAdjusted) {
        await _loadOrders(showLoading: false);
      }
      _showSnackBar('Order updated to ${newStatus.displayLabel}');
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          final rollbackIndex = _orders.indexWhere(
            (order) => order.id == orderId,
          );
          if (rollbackIndex != -1) {
            _orders[rollbackIndex] = previousOrder;
          }
        });
      }
      debugPrint('[StoreOrdersScreen] _updateStatus: $e\n$stack');
      _showSnackBar('Failed to update order', isError: true);
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _bulkRejectOrders() async {
    final reason = await _selectBulkRejectionReason();
    if (reason == null || !mounted) return;

    setState(() => _isLoading = true);

    int successCount = 0;
    int failCount = 0;

    for (final orderId in _selectedOrderIds) {
      try {
        await context.read<StoreProvider>().updateOrderStatus(
          orderId,
          OrderStatus.cancelled.backendName,
          rejectionReason: reason,
        );
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Failed to bulk reject order $orderId: $e');
      }
    }

    setState(() {
      _isSelectionMode = false;
      _selectedOrderIds.clear();
    });

    await _loadOrders();

    if (failCount > 0) {
      _showSnackBar(
        'Bulk reject completed: $successCount succeeded, $failCount failed',
        isWarning: true,
      );
    } else {
      _showSnackBar('Successfully rejected $successCount orders');
    }
  }

  Future<String?> _selectBulkRejectionReason() async {
    final controller = TextEditingController();
    const customReason = 'Custom';

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogCtx) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          var selectedReason = 'Out of stock';
          String? customError;

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: isDark ? null : Colors.white,
              title: const Text('Reject Selected Orders'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a reason for rejecting ${_selectedOrderIds.length} orders.',
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selectedReason == 'Out of stock'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Out of stock'),
                    onTap: () {
                      setDialogState(() {
                        selectedReason = 'Out of stock';
                        customError = null;
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selectedReason == 'Not taking orders'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Not taking orders'),
                    onTap: () {
                      setDialogState(() {
                        selectedReason = 'Not taking orders';
                        customError = null;
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selectedReason == customReason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Custom'),
                    onTap: () {
                      setDialogState(() {
                        selectedReason = customReason;
                      });
                    },
                  ),
                  if (selectedReason == customReason) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Enter rejection reason',
                        border: const OutlineInputBorder(),
                        errorText: customError,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    final reason = selectedReason == customReason
                        ? controller.text.trim()
                        : selectedReason;
                    if (reason.isEmpty) {
                      setDialogState(() {
                        customError = 'Enter a rejection reason';
                      });
                      return;
                    }
                    Navigator.pop(dialogCtx, reason);
                  },
                  child: const Text('Reject'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  // ── Ably ───────────────────────────────────────────────────────────────────

  void _subscribeAbly() {
    ablyService.addOrderListener((orderId, status) {
      if (!mounted) return;

      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        setState(() {
          _orders[index] = _orders[index].copyWith(status: status);
        });
        return;
      }

      _loadOrders(showLoading: false);
      setState(() => _hasNewOrder = true);
    });
  }

  // ── Unattended Notification Reminders ──────────────────────────────────────

  void _initAudioPlayer() {
    try {
      _reminderAudioPlayer = AudioPlayer();
    } catch (e) {
      debugPrint('Failed to initialize reminder audio player: $e');
    }
  }

  void _startUnattendedTimer() {
    _unattendedTimer?.cancel();
    _unattendedTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkUnattendedOrdersAndNotify();
    });
  }

  void _checkUnattendedOrdersAndNotify() {
    if (!mounted || _orders.isEmpty) return;

    final now = DateTime.now();
    final unattendedOrders = <Order>[];

    for (final order in _orders) {
      final isPickup = _isPickupDeliveryType(order.deliveryType);
      if (isPickup) continue;

      final isActive =
          order.status == OrderStatus.pending ||
          order.status == OrderStatus.accepted ||
          order.status == OrderStatus.preparing;
      if (!isActive) continue;

      if (_dismissedUnattendedOrderIds.contains(order.id)) continue;

      if (order.date.isNotEmpty) {
        try {
          final dt = DateTime.parse(order.date).toLocal();
          final elapsed = now.difference(dt).inMinutes;
          if (elapsed >= 5) {
            unattendedOrders.add(order);
          }
        } catch (_) {}
      }
    }

    if (unattendedOrders.isNotEmpty) {
      if (_lastNotificationTime == null ||
          now.difference(_lastNotificationTime!).inMinutes >= 5) {
        _lastNotificationTime = now;
        _playReminderSound();
        _showUnattendedAlert(unattendedOrders);
      }
    }
  }

  void _playReminderSound() {
    try {
      _reminderAudioPlayer?.play(AssetSource('sounds/order_sound.mp3'));
    } catch (e) {
      debugPrint('Failed to play reminder sound: $e');
    }
  }

  void _showUnattendedAlert(List<Order> unattendedOrders) {
    if (!mounted) return;

    final shortIds = unattendedOrders
        .map((o) => '#${_shortId(o.id).toUpperCase()}')
        .join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shake(delay: 500.ms, duration: 1000.ms),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'UNATTENDED DELIVERY ORDERS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Orders: $shortIds are unattended. Please attend to them.',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 12),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(
          label: 'DISMISS ALL',
          textColor: Colors.white,
          onPressed: () {
            _reminderAudioPlayer?.stop();
            setState(() {
              for (final o in unattendedOrders) {
                _dismissedUnattendedOrderIds.add(o.id);
              }
            });
          },
        ),
      ),
    );
  }

  // ── Pickup scanner ─────────────────────────────────────────────────────────

  Future<void> _openPickupScanner() async {
    if (!mounted) return;

    final scanOrders = _orders.map((o) => ScanOrder(o.id)).toList();
    final confirmedId = await PickupScannerSheet.show(
      context,
      orders: scanOrders,
    );

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
      _showSnackBar(
        'Order is not ready for pickup (status: ${matched.status.name}).',
        isWarning: true,
      );
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _isPickupDeliveryType(String deliveryType) {
    final t = deliveryType.toLowerCase();
    return t == 'pickup' || t == 'store_pickup';
  }

  static String _shortId(String id) =>
      id.length >= 8 ? id.substring(id.length - 8) : id;

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
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

  Widget _buildTypeChip(
    String type,
    String label,
    Color surfaceColor,
    Color borderColor,
    bool isDark,
  ) {
    final isSelected = _deliveryTypeFilter == type;
    final primary = AppColors.primary;

    return GestureDetector(
      onTap: () => setState(() => _deliveryTypeFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primary : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? primary
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
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
        title: OrderAppBarTitle(
          hasNewOrder: _hasNewOrder,
          badgeScale: _badgeScale,
        ),
        actions: [
          IconButton(
            tooltip: _isSelectionMode ? 'Exit Selection' : 'Select Orders',
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.checklist_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  _selectedOrderIds.clear();
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Verify Pickup',
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
            ),
            onPressed: _openPickupScanner,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadOrders(showLoading: false);
              setState(() => _hasNewOrder = false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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
          // ── Beautiful Type Separation Filters ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTypeChip(
                    'all',
                    '🍱 All Orders',
                    surface,
                    border,
                    isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildTypeChip(
                    'delivery',
                    '🛵 Delivery',
                    surface,
                    border,
                    isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildTypeChip(
                    'pickup',
                    '🛍️ Pickup',
                    surface,
                    border,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _loadOrders(showLoading: false),
                    child: _filtered.isEmpty
                        ? OrderEmptyState(muted: muted)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final order = _filtered[i];
                              final isSelected = _selectedOrderIds.contains(
                                order.id,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    if (_isSelectionMode) ...[
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: AppColors.primary,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedOrderIds.add(order.id);
                                            } else {
                                              _selectedOrderIds.remove(
                                                order.id,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: OrderCard(
                                        order: order,
                                        isUpdating: _updatingOrderIds.contains(
                                          order.id,
                                        ),
                                        textColor: textColor,
                                        muted: muted,
                                        surface: surface,
                                        border: border,
                                        onUpdateStatus: _updateStatus,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(top: BorderSide(color: border)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedOrderIds.length} Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedOrderIds.length == _filtered.length) {
                            _selectedOrderIds.clear();
                          } else {
                            _selectedOrderIds.addAll(
                              _filtered.map((o) => o.id),
                            );
                          }
                        });
                      },
                      child: Text(
                        _selectedOrderIds.length == _filtered.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _selectedOrderIds.isEmpty
                          ? null
                          : _bulkRejectOrders,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text(
                        'Reject Selected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
