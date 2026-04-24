import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/auth_provider.dart';
import '../sheets/edit_profile_sheet.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.auth});

  final dynamic user;
  final AuthProvider auth;

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            ],
          ).animate().scale(
            delay: 100.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'LaunchFast User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),
                const SizedBox(height: 8),
                _RoleBadge(role: user.role),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => _showEditModal(context),
            icon: const Icon(Icons.edit_outlined, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ).animate().fadeIn(delay: 400.ms).scale(),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        role.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5);
  }
}
