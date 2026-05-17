import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'widgets/transaction_history_section.dart';
import '../../../../providers/payment_provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded, 
            size: 18,
            color: scheme.onSurface,
          ),
        ),
        title: Text(
          'Transactions',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator.adaptive(
        color: scheme.primary,
        onRefresh: () => context.read<PaymentProvider>().fetchTransactions(),
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              TransactionHistorySection(),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
