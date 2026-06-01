import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/payment_provider.dart';
import '../../../../models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TransactionHistorySection extends StatefulWidget {
  const TransactionHistorySection({super.key});

  @override
  State<TransactionHistorySection> createState() =>
      _TransactionHistorySectionState();
}

class _TransactionHistorySectionState extends State<TransactionHistorySection> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Deposits', 'Orders', 'Cashback'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PaymentProvider>().fetchTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                    }
                  },
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? scheme.onSurface.withValues(alpha: 0.7)
                              : Colors.grey[700]),
                  ),
                  selectedColor: scheme.primary,
                  backgroundColor: isDark
                      ? scheme.surfaceContainerHighest
                      : Colors.grey[100],
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Transactions List
        if (payment.isLoading && payment.transactions.isEmpty)
          Column(
            children: List.generate(
              5,
              (i) => _TransactionSkeleton(isDark: isDark, delay: i * 60),
            ),
          )
        else if (payment.transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: isDark
                        ? scheme.onSurface.withValues(alpha: 0.1)
                        : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: isDark
                          ? scheme.onSurface.withValues(alpha: 0.4)
                          : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._getFilteredTransactions(
            payment.transactions,
          ).map((tx) => _TransactionTile(tx: tx)),
      ],
    );
  }

  List<TransactionItem> _getFilteredTransactions(List<TransactionItem> txs) {
    if (_selectedFilter == 'All') return txs;
    if (_selectedFilter == 'Deposits') {
      return txs
          .where(
            (t) =>
                t.purpose.toLowerCase().contains('deposit') ||
                t.purpose.toLowerCase().contains('top-up'),
          )
          .toList();
    }
    if (_selectedFilter == 'Orders') {
      return txs
          .where((t) => t.purpose.toLowerCase().contains('order'))
          .toList();
    }
    if (_selectedFilter == 'Cashback') {
      return txs
          .where((t) => t.purpose.toLowerCase().contains('cashback'))
          .toList();
    }
    return txs;
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCredit = tx.isCredit;

    final creditColor = isDark ? Colors.greenAccent[400]! : Colors.green[700]!;
    final debitColor = scheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.5)
              : Colors.grey[100]!,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  (isCredit
                          ? creditColor
                          : (isDark ? scheme.primary : Colors.blue))
                      .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.shopping_bag_outlined,
              color: isCredit
                  ? creditColor
                  : (isDark ? scheme.primary : Colors.blue),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.purpose,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy • hh:mm a').format(tx.createdAt),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : "-"}₦${tx.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isCredit ? creditColor : debitColor,
                ),
              ),
              const SizedBox(height: 4),
              _StatusBadge(status: tx.status),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    String label;

    switch (status) {
      case TransactionStatus.success:
        color = isDark ? Colors.greenAccent[400]! : Colors.green;
        label = 'Completed';
        break;
      case TransactionStatus.failed:
        color = Colors.redAccent;
        label = 'Failed';
        break;
      case TransactionStatus.pending:
        color = Colors.orangeAccent;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TransactionSkeleton extends StatelessWidget {
  final bool isDark;
  final int delay;
  const _TransactionSkeleton({required this.isDark, required this.delay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = isDark ? Colors.white10 : Colors.black12;
    final highlight = isDark ? Colors.white24 : Colors.white70;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.5)
              : Colors.grey[100]!,
        ),
      ),
      child: Row(
        children: [
          _Bone(44, 44, 22, base),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(double.infinity, 14, 6, base),
                const SizedBox(height: 6),
                _Bone(120, 12, 6, base),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bone(60, 16, 6, base),
              const SizedBox(height: 6),
              _Bone(48, 18, 6, base),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .shimmer(duration: 1200.ms, color: highlight)
        .fadeIn(duration: 250.ms);
  }
}

class _Bone extends StatelessWidget {
  final double w, h, r;
  final Color color;
  const _Bone(this.w, this.h, this.r, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}
