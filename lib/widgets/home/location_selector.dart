import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LocationSelector extends StatelessWidget {
  const LocationSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final hasLocation = authProvider.currentAddress != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLocationPicker(context, authProvider),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: hasLocation
                ? scheme.primary.withValues(alpha: 0.06)
                : scheme.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasLocation
                  ? scheme.primary.withValues(alpha: 0.2)
                  : scheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: hasLocation ? scheme.primary : scheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  authProvider.currentAddress ?? 'Set delivery location...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasLocation
                        ? scheme.onSurface.withValues(alpha: 0.85)
                        : scheme.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return _showLocationPickerStatic(context, authProvider);
  }

  void _showLocationPicker(BuildContext context, AuthProvider authProvider) {
    _showLocationPickerStatic(context, authProvider);
  }

  static Future<void> _showLocationPickerStatic(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final locations = authProvider.locations;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LocationPickerSheet(
        locations: locations,
        authProvider: authProvider,
      ),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final List<String> locations;
  final AuthProvider authProvider;

  const _LocationPickerSheet({
    required this.locations,
    required this.authProvider,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  bool _showCustomInput = false;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectLocation(String loc) async {
    try {
      await widget.authProvider.setDeliveryAddress(loc);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update address: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentAddress = widget.authProvider.currentAddress;

    return ConstrainedBox(
      // Cap sheet at 80% of screen height — prevents overflow on any device
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delivery Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select where you want your order delivered',
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 20),

              // ── Scrollable locations list ─────────────────────────────────
              // Flexible lets it shrink when few items, scroll when many
              if (widget.locations.isNotEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...widget.locations.map((loc) {
                          final isSelected = currentAddress == loc;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Material(
                                color: isSelected
                                    ? scheme.primary.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () => _selectLocation(loc),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? scheme.primary
                                                .withValues(alpha: 0.4)
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? scheme.primary
                                                : Colors.black
                                                    .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.home_work_rounded,
                                            size: 18,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black45,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            loc,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              fontSize: 15,
                                              color: isSelected
                                                  ? scheme.primary
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: scheme.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),

              // ── Custom address input ──────────────────────────────────────
              // Always outside scroll area so it stays pinned to bottom
              if (_showCustomInput) ...[
                const Divider(height: 24),
                TextField(
                  controller: _customCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Enter your address',
                    hintText: 'e.g. Block C, Room 204, Hall 3',
                    prefixIcon: const Icon(Icons.edit_location_alt_rounded),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: scheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final text = _customCtrl.text.trim();
                      if (text.isNotEmpty) _selectLocation(text);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Use This Address',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showCustomInput = true),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Enter a custom address'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
