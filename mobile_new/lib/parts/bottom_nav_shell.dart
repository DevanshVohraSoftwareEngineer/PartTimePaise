import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async {
        // If not on Home (Explore) tab (index 0), go back to Home
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return false; // Prevent app exit
        }
        return true; // Allow app exit from Home
      },
      child: Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          height: 65, // More compact
          elevation: 0,
          backgroundColor: isDark ? Colors.black : Colors.white,
          indicatorColor: Colors.transparent, // Minimalist: No indicator, just color change
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _buildNavItem(Icons.explore_outlined, Icons.explore, 'Explore', isDark),
            _buildCustomHubItem(isDark),
            _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', isDark),
            _buildNavItem(Icons.add_circle_outline, Icons.add_circle, 'Post', isDark),
            _buildNavItem(Icons.assignment_outlined, Icons.assignment, 'Posted', isDark),
            _buildNavItem(Icons.work_outline, Icons.work, 'Applied', isDark),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile', isDark),
          ],
        ),
      ),
      ),
    );
  }

  NavigationDestination _buildNavItem(IconData icon, IconData selectedIcon, String label, bool isDark) {
    return NavigationDestination(
      icon: Icon(icon, color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5), size: 24),
      selectedIcon: Icon(selectedIcon, color: isDark ? Colors.white : Colors.black, size: 24),
      label: label,
    );
  }

  NavigationDestination _buildCustomHubItem(bool isDark) {
    final bool isSelected = navigationShell.currentIndex == 1;
    return NavigationDestination(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white24,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.lightbulb_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
      selectedIcon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.white24 : Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.lightbulb_rounded,
          color: isDark ? Colors.black : Colors.white,
          size: 18,
        ),
      ),
      label: 'Hub',
    );
  }
}
