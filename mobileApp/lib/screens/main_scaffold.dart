import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'student_list_screen.dart';
import 'collect_fee_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const StudentListScreen(),
    const CollectFeeScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: AppTheme.textSecondary.withOpacity(0.5),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined, size: 24),
                  activeIcon: Icon(Icons.grid_view_rounded, size: 24),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline_rounded, size: 24),
                  activeIcon: Icon(Icons.people_rounded, size: 24),
                  label: 'Students',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payments_outlined, size: 24),
                  activeIcon: Icon(Icons.payments_rounded, size: 25),
                  label: 'Fees',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined, size: 24),
                  activeIcon: Icon(Icons.bar_chart_rounded, size: 24),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined, size: 24),
                  activeIcon: Icon(Icons.settings_rounded, size: 24),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
