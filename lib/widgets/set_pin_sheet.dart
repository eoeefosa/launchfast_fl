import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/wallet_repository.dart';
import '../services/api_service.dart';

/// Two-step "enter new PIN → confirm PIN" flow.
/// Call [SetPinSheet.show] — resolves true when PIN is set successfully.
class SetPinSheet extends StatefulWidget {
  const SetPinSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SetPinSheet(),
    );
    return result ?? false;
  }

  @override
  State<SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<SetPinSheet> {
  final _first = <String>[];
  final _confirm = <String>[];
  bool _confirming = false;
  bool _isLoading = false;
  String? _error;

  void _onKey(String digit) {
    if (_isLoading) return;
    final target = _confirming ? _confirm : _first;
    if (target.length >= 4) return;
    setState(() {
      target.add(digit);
      _error = null;
    });
    if (target.length == 4) {
      if (!_confirming) {
        setState(() => _confirming = true);
      } else {
        _submit();
      }
    }
  }

  void _onDelete() {
    if (_isLoading) return;
    setState(() {
      if (_confirming && _confirm.isNotEmpty) {
        _confirm.removeLast();
      } else if (!_confirming && _first.isNotEmpty) {
        _first.removeLast();
      }
    });
  }

  Future<void> _submit() async {
    if (_first.join() != _confirm.join()) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirming = false;
        _first.clear();
        _confirm.clear();
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      await WalletRepository().setTransactionPin(_first.join());
      if (!mounted) return;
      // Mark hasTransactionPin locally
      context.read<AuthProvider>().updateUser({'hasTransactionPin': true});
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = ApiService.getErrorMessage(e);
          _confirming = false;
          _first.clear();
          _confirm.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _confirming ? _confirm : _first;
    final title = _confirming ? 'Confirm your PIN' : 'Set a Transaction PIN';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24, left: 24, right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _confirming ? 'Re-enter your 4-digit PIN' : 'Choose a 4-digit PIN to secure your transactions',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < current.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? theme.colorScheme.primary : Colors.transparent,
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            _buildKeypad(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return TextButton(
          onPressed: k == '⌫' ? _onDelete : () => _onKey(k),
          child: Text(k, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
        );
      }).toList(),
    );
  }
}
