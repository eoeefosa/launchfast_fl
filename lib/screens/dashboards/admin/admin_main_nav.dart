import 'package:flutter/material.dart';
import 'package:launchfast_fl/constants/app_colors.dart';
import 'package:launchfast_fl/screens/dashboards/admin/admin_dashboard_home.dart';
import 'package:launchfast_fl/screens/dashboards/admin/user_management_screen.dart';
import 'package:launchfast_fl/screens/dashboards/admin/activity_monitor_screen.dart';

class AdminMainNav extends StatefulWidget {
  const AdminMainNav({super.key});

  @override
  State<AdminMainNav> createState() => _AdminMainNavState();
}

class _AdminMainNavState extends State<AdminMainNav> {
  int _currentIndex = 0;

  static const List<({String label, IconData icon, IconData activeIcon})>
      _navItems = [
    (
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    (
      label: 'Users',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    (
      label: 'Activity',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_rounded,
    ),
  ];

  final List<Widget> _pages = [
    const AdminDashboardHome(),
    const AdminUserManagementScreen(),
    const ActivityMonitorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          height: 70,
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = _currentIndex == i;

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        size: 24,
                        color: isActive
                            ? AppColors.primary
                            : isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted,
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
