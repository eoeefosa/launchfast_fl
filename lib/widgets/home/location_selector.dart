import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LocationSelector extends StatelessWidget {
  /// Convenience method to display the location picker.
  static Future<void> show(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Use the instance method to handle the picker logic.
    LocationSelector()._showLocationPicker(context, authProvider);
  }

  const LocationSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLocation = authProvider.currentAddress != null;

    // ── AppColors ────────────────────────────────────────────────────────
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final errorColor = Colors.redAccent;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLocationPicker(context, authProvider),
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: hasLocation
                ? (isDark
                      ? AppColors.darkSurface2.withValues(alpha: 0.6)
                      : accent.withValues(alpha: 0.06))
                : errorColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasLocation
                  ? (isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.5)
                        : accent.withValues(alpha: 0.2))
                  : errorColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20.sp,
                color: hasLocation ? accent : errorColor,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  authProvider.currentAddress ?? 'Set delivery location...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: hasLocation ? textColor : errorColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20.sp,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, AuthProvider authProvider) {
    final locations = authProvider.locations;

    // If the list is long, use a dialog with scrollable content for better UX
    if (locations.length > 5) {
      _showLocationDialog(context, authProvider, locations);
    } else {
      _showLocationBottomSheet(context, authProvider, locations);
    }
  }

  void _showLocationBottomSheet(
    BuildContext context,
    AuthProvider authProvider,
    List<String> locations,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LocationPickerSheet(
        locations: locations,
        authProvider: authProvider,
        isDialog: false,
      ),
    );
  }

  void _showLocationDialog(
    BuildContext context,
    AuthProvider authProvider,
    List<String> locations,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _LocationPickerSheet(
        locations: locations,
        authProvider: authProvider,
        isDialog: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable picker widget (used both as bottom sheet and dialog)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerSheet extends StatefulWidget {
  final List<String> locations;
  final AuthProvider authProvider;
  final bool isDialog;

  const _LocationPickerSheet({
    required this.locations,
    required this.authProvider,
    required this.isDialog,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;
    final cardBg = isDark ? AppColors.darkSurface2 : AppColors.lightSurface;
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : AppColors.lightBorder.withValues(alpha: 0.5);

    final currentAddress = widget.authProvider.currentAddress;

    // ── Content layout ────────────────────────────────────────────────────
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle (only in bottom sheet)
        if (!widget.isDialog) ...[
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white38 : Colors.black12,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ],

        // Title
        Text(
          'Delivery Location',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Select where you want your order delivered',
          style: TextStyle(fontSize: 13.sp, color: mutedColor),
        ),
        SizedBox(height: 20.h),

        // ── Locations list (scrollable) ───────────────────────────────────
        if (widget.locations.isNotEmpty)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...widget.locations.map((loc) {
                    final isSelected = currentAddress == loc;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Material(
                          color: isSelected
                              ? accent.withValues(alpha: 0.08)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.black.withValues(alpha: 0.03)),
                          borderRadius: BorderRadius.circular(14.r),
                          child: InkWell(
                            onTap: () => _selectLocation(loc),
                            borderRadius: BorderRadius.circular(14.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accent
                                          : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.05,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  )),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(
                                      Icons.home_work_rounded,
                                      size: 18.sp,
                                      color: isSelected
                                          ? Colors.white
                                          : mutedColor,
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Text(
                                      loc,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 15.sp,
                                        color: isSelected ? accent : textColor,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: accent,
                                      size: 20.sp,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

        // ── Custom address input ──────────────────────────────────────────
        if (_showCustomInput) ...[
          SizedBox(height: 8.h),
          Divider(color: borderColor, height: 1),
          SizedBox(height: 16.h),
          TextField(
            controller: _customCtrl,
            autofocus: true,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Enter your address',
              hintText: 'e.g. Block C, Room 204, Hall 3',
              labelStyle: TextStyle(color: mutedColor),
              prefixIcon: Icon(Icons.edit_location_alt_rounded, color: accent),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurface2.withValues(alpha: 0.5)
                  : AppColors.lightSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: accent, width: 2),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final text = _customCtrl.text.trim();
                if (text.isNotEmpty) _selectLocation(text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
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
              icon: Icon(Icons.add_location_alt_rounded, color: accent),
              label: Text(
                'Enter a custom address',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 8.h),
      ],
    );

    // ── Render as dialog or bottom sheet ──────────────────────────────────
    if (widget.isDialog) {
      return Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.70, // scrollable dialog
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
            child: content,
          ),
        ),
      );
    } else {
      // Bottom sheet
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.w,
              24.h,
              24.w,
              MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            child: SingleChildScrollView(child: content),
          ),
        ),
      );
    }
  }
}
