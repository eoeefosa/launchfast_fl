import 'package:flutter/material.dart';
import 'package:launchfast/constants/app_colors.dart';
import 'package:launchfast/screens/dashboards/rider/active_delivers.dart';
import 'package:launchfast/screens/dashboards/rider/rider_dashboard.dart';
import 'package:launchfast/screens/tabs/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final screens = const [
    RiderDashboard(),
    ActiveDeliveryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Delivery"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
