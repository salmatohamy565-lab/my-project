import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/employee/employee_files_screen.dart';
import '../screens/products/products_screen.dart';

class EmployeeDrawer extends StatelessWidget {
  final String activeRoute;

  const EmployeeDrawer({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header / Sidebar brand
          Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 28.h),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
                SizedBox(width: 14.w),
                Text(
                  'Bola Designs',
                  style: AppStyles.labelBold.copyWith(
                    fontSize: 16.sp,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              children: [
                _buildNavItem(
                  context: context,
                  title: 'لوحة الموظف',
                  icon: Icons.home_outlined,
                  route: 'dashboard',
                  destination: const EmployeeDashboard(),
                ),
                _buildNavItem(
                  context: context,
                  title: 'ملفاتي',
                  icon: Icons.folder_open_outlined,
                  route: 'files',
                  destination: const EmployeeFilesScreen(),
                ),
                _buildNavItem(
                  context: context,
                  title: 'منتجاتي',
                  icon: Icons.shopping_bag_outlined,
                  route: 'products',
                  destination: const ProductsScreen(),
                ),
              ],
            ),
          ),
          // Logout Button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: _buildLogoutBtn(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
    required Widget destination,
  }) {
    final isActive = activeRoute == route;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () {
          // Close drawer
          Navigator.of(context).pop();
          if (isActive) return;
          // Navigate to new screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryAccent.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isActive ? AppColors.primaryAccent.withOpacity(0.18) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primaryAccent : AppColors.textMuted,
                size: 20,
              ),
              SizedBox(width: 14.w),
              Text(
                title,
                style: AppStyles.bodyDefault.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.textMain : AppColors.textDefault,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutBtn(BuildContext context) {
    return InkWell(
      onTap: () async {
        Navigator.of(context).pop();
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.dangerGradient),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white, size: 18),
            SizedBox(width: 10.w),
            Text(
              'تسجيل الخروج',
              style: AppStyles.labelBold.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
