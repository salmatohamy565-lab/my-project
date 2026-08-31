import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/attendance_screen.dart';
import '../screens/admin/admin_files_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/employee/employee_files_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/products_screen.dart';
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
    final user = context.watch<AuthProvider>().currentUser;
    final cartCount = context.watch<CartProvider>().itemCount;

    List<Map<String, dynamic>> items;
    if (user != null && user.isAdmin) {
      items = _adminItems();
    } else if (user != null && user.isEmployee) {
      items = _employeeItems();
    } else {
      items = _customerItems();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, (bottomPadding > 0 ? bottomPadding : 12.h)),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
        children: [
          for (final item in items)
            Builder(builder: (context) {
              final bool isActive = item['route'] == currentRoute;
              final Widget destination = item['destination'] as Widget;
              final IconData activeIcon = item['activeIcon'] as IconData;
              final IconData inactiveIcon = item['inactiveIcon'] as IconData;
              final String? title = item['title'] as String?;

              return GestureDetector(
                onTap: () {
                  if (isActive) return;
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => destination,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? activeIcon : inactiveIcon,
                            color: isActive ? AppColors.primaryAccent : AppColors.textMuted,
                            size: 22.r,
                          ),
                          // Badge for Cart counter
                          if (item['route'] == 'cart' && cartCount > 0)
                            Positioned(
                              top: -4.h,
                              right: -6.w,
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16.r,
                                  minHeight: 16.r,
                                ),
                                child: Text(
                                  '$cartCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (title != null && title.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          title,
                          style: TextStyle(
                            color: isActive ? AppColors.primaryAccent : AppColors.textMuted,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _adminItems() {
    return [
      {
        'route': 'dashboard',
        'title': 'الرئيسية',
        'inactiveIcon': Icons.grid_view_rounded,
        'activeIcon': Icons.grid_view_rounded,
        'destination': const AdminDashboard(),
      },
      {
        'route': 'attendance',
        'title': 'الحضور',
        'inactiveIcon': Icons.calendar_month_outlined,
        'activeIcon': Icons.calendar_month_rounded,
        'destination': const AttendanceScreen(),
      },
      {
        'route': 'products',
        'title': 'المنتجات',
        'inactiveIcon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag_rounded,
        'destination': ProductsScreen(),
      },
      {
        'route': 'profile',
        'title': 'حسابي',
        'inactiveIcon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'destination': const ProfileScreen(),
      },
    ];
  }

  List<Map<String, dynamic>> _employeeItems() {
    return [
      {
        'route': 'products',
        'title': 'المنتجات',
        'inactiveIcon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag_rounded,
        'destination': ProductsScreen(),
      },
      {
        'route': 'files',
        'title': 'الملفات',
        'inactiveIcon': Icons.folder_open_outlined,
        'activeIcon': Icons.folder_rounded,
        'destination': const EmployeeFilesScreen(),
      },
      {
        'route': 'profile',
        'title': 'حسابي',
        'inactiveIcon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'destination': const ProfileScreen(),
      },
    ];
  }

  List<Map<String, dynamic>> _customerItems() {
    return [
      {
        'route': 'cart',
        'title': 'Cart',
        'inactiveIcon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart_rounded,
        'destination': const CartScreen(),
      },
      {
        'route': 'home',
        'title': 'Home',
        'inactiveIcon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
        'destination': const HomeScreen(),
      },
      {
        'route': 'profile',
        'title': 'Account',
        'inactiveIcon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'destination': const ProfileScreen(),
      },
    ];
  }
}
