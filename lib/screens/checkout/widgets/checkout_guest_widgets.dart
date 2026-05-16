import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/home/location_selector.dart';

class GuestAddressTile extends StatelessWidget {
  const GuestAddressTile({super.key, required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => LocationSelector.show(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: primary.withValues(alpha: 0.1),
                ),
                child: SizedBox(
                  height: 52,
                  width: 52,
                  child: Icon(Icons.location_on_rounded, color: primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.currentAddress ?? 'Set delivery address',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to select location',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
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
    return Column(
      children: [
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full name',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Phone number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                onError('Please enter your full name and phone number.');
                return;
              }
              onContinue();
            },
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
