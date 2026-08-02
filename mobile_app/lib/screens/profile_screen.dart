import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/radial_background.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/app_logo_bar.dart';
import 'login_screen.dart';
import 'admin/archived_tasks_screen.dart';
import 'admin/archived_files_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final bool isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(
              username: currentUser?.username ?? 'المستخدم',
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar & Info section
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50.r,
                            backgroundColor: AppColors.primaryAccent.withOpacity(0.08),
                            child: Icon(
                              Icons.person_rounded,
                              size: 56.r,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            currentUser?.username ?? 'اسم المستخدم',
                            style: AppStyles.titleMedium.copyWith(fontSize: 20.sp),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              isAdmin ? 'مسؤول النظام' : 'مشرف / موظف',
                              style: AppStyles.labelBold.copyWith(
                                color: AppColors.primaryAccent,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Actions list
                    Text(
                      'الإعدادات والخيارات',
                      style: AppStyles.labelBold.copyWith(fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        children: [
                          if (isAdmin) ...[
                            _buildListTile(
                              icon: Icons.archive_outlined,
                              title: 'المهام المؤرشفة',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ArchivedTasksScreen()),
                                );
                              },
                            ),
                            const Divider(color: AppColors.borderLight, height: 1),
                            _buildListTile(
                              icon: Icons.folder_open_outlined,
                              title: 'الملفات المؤرشفة',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ArchivedFilesScreen()),
                                );
                              },
                            ),
                            const Divider(color: AppColors.borderLight, height: 1),
                          ],
                          _buildListTile(
                            icon: Icons.info_outline_rounded,
                            title: 'المعلومات الشخصية',
                            onTap: () {
                              _showPersonalInfoDialog(context, currentUser?.username ?? '', isAdmin ? 'مسؤول النظام' : 'مشرف / موظف');
                            },
                          ),
                          const Divider(color: AppColors.borderLight, height: 1),
                          _buildListTile(
                            icon: Icons.support_agent_rounded,
                            title: 'الدعم والمساعدة',
                            onTap: () {
                              _showSupportDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Logout Button
                    ElevatedButton(
                      onPressed: () async {
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerStart,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 8.w),
                          Text(
                            'تسجيل الخروج',
                            style: AppStyles.labelBold.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentRoute: 'profile',
        isAdmin: isAdmin,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent),
      title: Text(
        title,
        style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  void _showPersonalInfoDialog(BuildContext context, String username, String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('المعلومات الشخصية', textAlign: TextAlign.right, style: AppStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDialogInfoRow('اسم المستخدم:', username),
            SizedBox(height: 12.h),
            _buildDialogInfoRow('الدور الوظيفي:', role),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(value, style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppStyles.bodyMuted),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('الدعم والمساعدة', textAlign: TextAlign.right, style: AppStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'للدعم والاستفسار يرجى التواصل مع الإدارة أو Bola Designs على الرقم التالي:',
              textAlign: TextAlign.right,
              style: AppStyles.bodyDefault,
            ),
            SizedBox(height: 16.h),
            Text(
              '01228569626',
              textAlign: TextAlign.center,
              style: AppStyles.titleLarge.copyWith(color: AppColors.primaryAccent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }
}
