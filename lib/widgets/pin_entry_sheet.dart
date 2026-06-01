import 'package:flutter/material.dart';

/// Shows a 4-digit PIN pad bottom sheet.
///
/// [title] — headline shown at top.
/// [onSubmit] — called with the entered PIN. Throw to show an error.
/// [onForgot] — optional "Forgot PIN?" callback.
class PinEntrySheet extends StatefulWidget {
  final String title;
  final Future<void> Function(String pin) onSubmit;
  final VoidCallback? onForgot;

  const PinEntrySheet({
    super.key,
    required this.title,
    required this.onSubmit,
    this.onForgot,
  });

  /// Resolves true when PIN confirmed, false if dismissed without confirming.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required Future<void> Function(String pin) onSubmit,
    VoidCallback? onForgot,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PinEntrySheet(
        title: title,
        onSubmit: onSubmit,
        onForgot: onForgot,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends State<PinEntrySheet> {
  final _pin = <String>[];
  bool _isLoading = false;
  String? _error;

  void _onKey(String digit) {
    if (_pin.length >= 4 || _isLoading) return;
    setState(() {
      _pin.add(digit);
      _error = null;
    });
    if (_pin.length == 4) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty || _isLoading) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.onSubmit(_pin.join());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
          _pin.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 20),
          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _pin.length;
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
          if (widget.onForgot != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onForgot,
              child: const Text('Forgot PIN?'),
            ),
          ],
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
          child: Text(
            k,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
    );
  }
}
