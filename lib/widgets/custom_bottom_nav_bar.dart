import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/attendance_screen.dart';
import '../screens/admin/admin_files_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/employee/employee_files_screen.dart';
import '../screens/profile_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final String currentRoute;
  final bool isAdmin;

  const CustomBottomNavBar({
    super.key,
    required this.currentRoute,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final List<Map<String, dynamic>> items = isAdmin ? _adminItems() : _employeeItems();

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, (bottomPadding > 0 ? bottomPadding : 16.h)),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20.r,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final bool isActive = item['route'] == currentRoute;
          return GestureDetector(
            onTap: () {
              if (isActive) return;
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => item['destination'],
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 150),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                isActive ? item['activeIcon'] : item['inactiveIcon'],
                color: isActive ? Colors.white : AppColors.textMuted,
                size: 24.r,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _adminItems() {
    return [
      {
        'route': 'dashboard',
        'inactiveIcon': Icons.grid_view_rounded,
        'activeIcon': Icons.grid_view_rounded,
        'destination': const AdminDashboard(),
      },
      {
        'route': 'attendance',
        'inactiveIcon': Icons.calendar_month_outlined,
        'activeIcon': Icons.calendar_month_rounded,
        'destination': const AttendanceScreen(),
      },
      {
        'route': 'files',
        'inactiveIcon': Icons.folder_open_outlined,
        'activeIcon': Icons.folder_rounded,
        'destination': const AdminFilesScreen(),
      },
      {
        'route': 'products',
        'inactiveIcon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag_rounded,
        'destination': const ProductsScreen(),
      },
      {
        'route': 'profile',
        'inactiveIcon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'destination': const ProfileScreen(),
      },
    ];
  }

  List<Map<String, dynamic>> _employeeItems() {
    return [
      {
        'route': 'dashboard',
        'inactiveIcon': Icons.grid_view_rounded,
        'activeIcon': Icons.grid_view_rounded,
        'destination': const EmployeeDashboard(),
      },
      {
        'route': 'files',
        'inactiveIcon': Icons.folder_open_outlined,
        'activeIcon': Icons.folder_rounded,
        'destination': const EmployeeFilesScreen(),
      },
      {
        'route': 'products',
        'inactiveIcon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag_rounded,
        'destination': const ProductsScreen(),
      },
      {
        'route': 'profile',
        'inactiveIcon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'destination': const ProfileScreen(),
      },
    ];
  }
}
