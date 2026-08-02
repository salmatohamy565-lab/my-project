import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/radial_background.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/app_logo_bar.dart';
import '../widgets/payment_methods_modal.dart';
import 'login_screen.dart';
import 'admin/archived_tasks_screen.dart';
import 'admin/archived_files_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    final initialName = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!
        : ((user?.username != null && user!.username!.isNotEmpty) ? user!.username! : 'salma');
    final initialPhone = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : '01271122860';

    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    File? selectedPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تعديل البيانات الشخصية',
                      style: AppStyles.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),

                    // Avatar Edit
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(type: FileType.image);
                          if (result != null && result.files.single.path != null) {
                            setModalState(() {
                              selectedPhoto = File(result.files.single.path!);
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 40.r,
                          backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                          backgroundImage: selectedPhoto != null
                              ? FileImage(selectedPhoto!) as ImageProvider
                              : (user?.photoUrl != null
                                  ? NetworkImage('${authProvider.baseUrl}${user!.photoUrl}') as ImageProvider
                                  : null),
                          child: (selectedPhoto == null && user?.photoUrl == null)
                              ? const Icon(Icons.camera_alt, color: AppColors.primaryAccent)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    TextField(
                      controller: nameCtrl,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    ),
                    SizedBox(height: 20.h),

                    ElevatedButton(
                      onPressed: () async {
                        final success = await authProvider.updateProfile(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          photo: selectedPhoto,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث البيانات بنجاح!'),
                              backgroundColor: AppColors.emeraldGreen,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('حفظ التعديلات', style: AppStyles.buttonText),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final bool isAdmin = currentUser?.isAdmin ?? false;
    final bool isCustomer = currentUser?.isCustomer ?? false;

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(
              username: currentUser?.displayName ?? 'المستخدم',
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 36.r,
                                backgroundColor: AppColors.primaryAccent.withOpacity(0.08),
                                backgroundImage: (currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty)
                                    ? NetworkImage(currentUser.photoUrl!.startsWith('http')
                                        ? currentUser.photoUrl!
                                        : '${authProvider.baseUrl}${currentUser.photoUrl}') as ImageProvider
                                    : null,
                                child: (currentUser?.photoUrl == null || currentUser!.photoUrl!.isEmpty)
                                    ? Icon(Icons.person_rounded, size: 40.r, color: AppColors.primaryAccent)
                                    : null,
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentUser?.displayName ?? 'المستخدم',
                                      style: AppStyles.titleMedium.copyWith(fontSize: 18.sp),
                                    ),
                                    if (currentUser?.email != null && currentUser!.email!.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(currentUser.email!, style: AppStyles.bodyMuted),
                                    ],
                                    if (currentUser?.phone != null && currentUser!.phone!.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(currentUser.phone!, style: AppStyles.bodyMuted),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryAccent),
                                onPressed: () => _showEditProfileDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Actions List
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.account_balance_wallet,
                            title: 'طرق الدفع والتحويل (كاش / انستاباي)',
                            onTap: () => PaymentMethodsModal.show(context),
                          ),
                          const Divider(color: AppColors.borderLight, height: 1),
                          if (isAdmin) ...[
                            _buildListTile(
                              icon: Icons.archive_outlined,
                              title: 'المهام المؤرشفة',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ArchivedTasksScreen()),
                              ),
                            ),
                            const Divider(color: AppColors.borderLight, height: 1),
                            _buildListTile(
                              icon: Icons.folder_open_outlined,
                              title: 'الملفات المؤرشفة',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ArchivedFilesScreen()),
                              ),
                            ),
                            const Divider(color: AppColors.borderLight, height: 1),
                          ],
                          _buildListTile(
                            icon: Icons.support_agent_rounded,
                            title: 'الدعم والمساعدة',
                            onTap: () => _showSupportDialog(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

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
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 8.w),
                          Text('تسجيل الخروج', style: AppStyles.labelBold.copyWith(color: Colors.white)),
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
