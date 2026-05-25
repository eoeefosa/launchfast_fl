import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Result returned from [ContactConfirmSheet.show].
class ContactInfo {
  final String name;
  final String phone;

  const ContactInfo({required this.name, required this.phone});
}

/// A bottom sheet shown before every order that confirms (or collects) both
/// the customer's display name and phone number.
///
/// - For Google sign-in users, `currentName` may be their Google display name.
///   They must confirm (or override) it so the store owner sees the right name.
/// - `needsName` controls whether the name field is shown (true for Google
///   users or anyone without a saved name).
/// - `needsPhone` controls whether the phone field is shown in edit mode by
///   default (true when no phone is on file).
///
/// Returns a [ContactInfo] on success, or null if cancelled.
class ContactConfirmSheet extends StatefulWidget {
  final String? currentName;
  final String? currentPhone;
  final bool needsName;
  final bool needsPhone;

  const ContactConfirmSheet({
    super.key,
    this.currentName,
    this.currentPhone,
    this.needsName = false,
    this.needsPhone = false,
  });

  static Future<ContactInfo?> show(
    BuildContext context, {
    String? currentName,
    String? currentPhone,
    bool needsName = false,
    bool needsPhone = false,
  }) {
    return showModalBottomSheet<ContactInfo>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: !needsPhone && !needsName, // disable drag if data required
      isDismissible: !needsPhone && !needsName,
      builder: (_) => ContactConfirmSheet(
        currentName: currentName,
        currentPhone: currentPhone,
        needsName: needsName,
        needsPhone: needsPhone,
      ),
    );
  }

  @override
  State<ContactConfirmSheet> createState() => _ContactConfirmSheetState();
}

class _ContactConfirmSheetState extends State<ContactConfirmSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  bool _editingName = false;
  bool _editingPhone = false;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName ?? '');
    _phoneCtrl = TextEditingController(text: widget.currentPhone ?? '');

    // Start in edit mode when data is missing
    _editingName =
        widget.needsName || (widget.currentName ?? '').trim().isEmpty;
    _editingPhone =
        widget.needsPhone || (widget.currentPhone ?? '').trim().isEmpty;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _hasName => _nameCtrl.text.trim().length >= 2;
  bool get _hasPhone => _phoneCtrl.text.trim().length >= 7;

  void _confirm() {
    bool valid = true;

    if (_nameCtrl.text.trim().length < 2) {
      setState(
        () => _nameError = 'Enter your full name (at least 2 characters)',
      );
      valid = false;
    }
    if (_phoneCtrl.text.trim().length < 7) {
      setState(() => _phoneError = 'Enter a valid phone number');
      valid = false;
    }
    if (!valid) return;

    HapticFeedback.lightImpact();
    Navigator.pop(
      context,
      ContactInfo(name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm your details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'The restaurant uses these to confirm your order',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Name field ─────────────────────────────────────────────────
            _SectionLabel(label: 'Your name', scheme: scheme),
            const SizedBox(height: 8),
            if (!_editingName && _hasName) ...[
              _ReadonlyRow(
                icon: Icons.badge_rounded,
                value: _nameCtrl.text,
                scheme: scheme,
                onEdit: () => setState(() {
                  _editingName = true;
                }),
              ),
            ] else ...[
              TextField(
                controller: _nameCtrl,
                autofocus: _editingName && !_editingPhone,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _nameError = null),
                decoration: _inputDecoration(
                  scheme: scheme,
                  hint: 'e.g. Chidi Okafor',
                  icon: Icons.badge_rounded,
                  errorText: _nameError,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
            ],
            const SizedBox(height: 16),

            // ── Phone field ─────────────────────────────────────────────────
            _SectionLabel(label: 'Phone number', scheme: scheme),
            const SizedBox(height: 8),
            if (!_editingPhone && _hasPhone) ...[
              _ReadonlyRow(
                icon: Icons.phone_in_talk_rounded,
                value: _phoneCtrl.text,
                scheme: scheme,
                onEdit: () => setState(() {
                  _editingPhone = true;
                }),
              ),
            ] else ...[
              TextField(
                controller: _phoneCtrl,
                autofocus: _editingPhone && _hasName,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                ],
                onChanged: (_) => setState(() => _phoneError = null),
                decoration: _inputDecoration(
                  scheme: scheme,
                  hint: '08012345678',
                  icon: Icons.phone_rounded,
                  errorText: _phoneError,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                onSubmitted: (_) => _confirm(),
              ),
            ],
            const SizedBox(height: 24),

            // ── Confirm button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  (_editingName || _editingPhone)
                      ? 'Save & Continue'
                      : 'Yes, these are correct',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ColorScheme scheme,
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      errorText: errorText,
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme scheme;

  const _SectionLabel({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ReadonlyRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final ColorScheme scheme;
  final VoidCallback onEdit;

  const _ReadonlyRow({
    required this.icon,
    required this.value,
    required this.scheme,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Change',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
