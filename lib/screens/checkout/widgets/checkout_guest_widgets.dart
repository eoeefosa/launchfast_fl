import 'package:campuschow/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/home/location_selector.dart';

class GuestAddressTile extends StatelessWidget {
  const GuestAddressTile({super.key, required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => LocationSelector.show(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          color: surfaceColor,
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: primaryColor.withValues(alpha: 0.1),
                ),
                child: SizedBox(
                  height: 52.h,
                  width: 52.w,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: primaryColor,
                    size: 24.sp,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.currentAddress ?? 'Set delivery address',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Tap to select location',
                      style: TextStyle(color: mutedColor, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}

class GuestContactForm extends StatelessWidget {
  const GuestContactForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.onContinue,
    required this.onError,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onContinue;
  final void Function(String) onError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Column(
      children: [
        ContactField(
          controller: nameController,
          label: 'Full name',
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: 18.h),
        ContactField(
          controller: phoneController,
          label: 'Phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 22.h),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(56.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                onError('Please enter your full name and phone number.');
                return;
              }
              onContinue();
            },
            child: Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
            ),
          ),
        ),
      ],
    );
  }
}

class GuestContactDialog extends StatefulWidget {
  const GuestContactDialog({
    super.key,
    required this.nameController,
    required this.phoneController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  State<GuestContactDialog> createState() => _GuestContactDialogState();
}

class _GuestContactDialogState extends State<GuestContactDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return AlertDialog(
      surfaceTintColor: Colors.transparent,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      icon: Icon(
        Icons.contact_phone_outlined,
        color: primaryColor,
        size: 42.sp,
      ),
      title: Text(
        'Contact Information',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18.sp,
          color: textColor,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your details to receive delivery and order updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: mutedColor),
            ),
            SizedBox(height: 18.h),
            ContactField(
              controller: widget.nameController,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            SizedBox(height: 16.h),
            ContactField(
              controller: widget.phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Text('Cancel', style: TextStyle(color: textColor)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  backgroundColor: primaryColor,
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ContactField extends StatelessWidget {
  const ContactField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightMuted;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 15.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: mutedColor),
        prefixIcon: Icon(icon, color: mutedColor, size: 20.sp),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18.r)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
    );
  }
}
