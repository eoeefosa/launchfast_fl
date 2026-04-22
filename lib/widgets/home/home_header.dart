import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const HomeHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user?.name != null ? '${user!.name} 👋' : 'Guest User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      user?.name != null ? user!.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              // Location selection logic
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user?.address ?? 'Set delivery location...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'What are you craving?',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[500],
                        size: 22,
                      ),
                      suffixIcon: Icon(
                        Icons.mic_none_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
