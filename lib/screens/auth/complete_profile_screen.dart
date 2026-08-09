import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_logo_bar.dart';
import '../../utils/web_file_picker.dart';
import '../admin/admin_dashboard.dart';
import '../employee/employee_dashboard.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _profilePhoto;
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoName;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    final initialName = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!
        : (user != null && user.username.isNotEmpty ? user.username : 'salma');
    final initialPhone = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : '01271122860';

    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _pickPhoto() async {
    final picked = await pickImageFile();
    if (picked != null) {
      setState(() {
        _profilePhotoBytes = picked.bytes;
        _profilePhotoName = picked.name;
        _profilePhoto = picked.file;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photo: _profilePhoto,
        photoBytes: _profilePhotoBytes,
        photoName: _profilePhotoName,
      );
    } catch (_) {}

    if (mounted) {
      final user = authProvider.currentUser;
      Widget targetScreen;
      if (user != null && user.isAdmin) {
        targetScreen = const AdminDashboard();
      } else if (user != null && user.isEmployee) {
        targetScreen = const EmployeeDashboard();
      } else {
        targetScreen = const HomeScreen();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetScreen),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: RadialBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              children: [
                const AppLogoBar(),
                SizedBox(height: 20.h),
                AnimatedEntrance(
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: AppColors.loginCardBg,
                      border: Border.all(color: AppColors.borderMedium),
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'إكمال الملف الشخصي',
                            style: AppStyles.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'أدخل معلوماتك الأساسية لتخصيص حسابك وسهولة التواصل',
                            style: AppStyles.bodyMuted,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20.h),

                          // Avatar Picker
                          Center(
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: Stack(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final completeAvatarImg = _profilePhotoBytes != null
                                          ? MemoryImage(_profilePhotoBytes!) as ImageProvider
                                          : (_profilePhoto != null
                                              ? FileImage(_profilePhoto!) as ImageProvider
                                              : authProvider.currentUser?.getProfileImageProvider(authProvider.baseUrl));
                                      return CircleAvatar(
                                        radius: 46.r,
                                        backgroundColor: AppColors.primaryAccent.withOpacity(0.12),
                                        backgroundImage: completeAvatarImg,
                                        onBackgroundImageError: completeAvatarImg != null ? (_, __) {} : null,
                                        child: completeAvatarImg == null
                                            ? const Icon(Icons.person, size: 48, color: AppColors.primaryAccent)
                                            : null,
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 16.r,
                                      backgroundColor: AppColors.primaryAccent,
                                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'الاسم الكامل',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryAccent),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال الاسم';
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),

                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'رقم الموبايل',
                              prefixIcon: Icon(Icons.phone_android_outlined, color: AppColors.primaryAccent),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال رقم الموبايل';
                              return null;
                            },
                          ),
                          SizedBox(height: 24.h),

                          ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            ),
                            child: authProvider.isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text('حفظ والمتابعة', style: AppStyles.buttonText.copyWith(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
