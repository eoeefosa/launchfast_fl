import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/wallet_repository.dart';
import '../../../auth/widgets/custom_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kQuickAmounts = <int>[1000, 2000, 5000];

// ─────────────────────────────────────────────────────────────────────────────
// TopUpSheet
// ─────────────────────────────────────────────────────────────────────────────

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key, required this.auth});

  final AuthProvider auth;

  static Future<void> show(BuildContext context, AuthProvider auth) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TopUpSheet(auth: auth),
    );
  }

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  late final TextEditingController _amountCtrl;
  bool _isLoading = false;

  double? get _parsedAmount => double.tryParse(_amountCtrl.text.trim());
  bool get _hasValidAmount => (_parsedAmount ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _selectQuickAmount(int amount) {
    _amountCtrl.text = amount.toString();
  }

  Future<void> _deposit() async {
    if (!_hasValidAmount) return;

    setState(() => _isLoading = true);
    try {
      final authorizationUrl = await WalletRepository().topUp(_parsedAmount!);
      
      final uri = Uri.parse(authorizationUrl);
      if (await canLaunchUrl(uri)) {
        if (mounted) Navigator.pop(context);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Top Up Wallet', style: Theme.of(context).textTheme.titleLarge),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '₦ '),
          ),
          const SizedBox(height: 16),
          Row(children: _kQuickAmounts.map((amt) => Expanded(child: TextButton(onPressed: () => _selectQuickAmount(amt), child: Text('₦$amt')))).toList()),
          const SizedBox(height: 24),
          CustomButton(label: 'Deposit', isLoading: _isLoading, onPressed: _deposit, primaryColor: scheme.primary),
        ],
      ),
    );
  }
}
