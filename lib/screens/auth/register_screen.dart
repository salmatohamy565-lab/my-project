import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_logo_bar.dart';
import 'complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم إنشاء الحساب بنجاح!' : 'مرحباً بك! تم إعداد الحساب ودخول التطبيق.'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
      );
    }
  }

  void _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الدخول بواسطة Google بنجاح!'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
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
                            'إنشاء حساب جديد',
                            style: AppStyles.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'قم بإنشاء حسابك للانضمام إلى منصة Bola Designs',
                            style: AppStyles.bodyMuted,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20.h),

                          if (authProvider.errorMessage != null && authProvider.errorMessage!.trim().isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.all(12.w),
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                color: AppColors.dangerStart.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: AppColors.dangerStart),
                              ),
                              child: Text(
                                authProvider.errorMessage!,
                                style: AppStyles.bodyDefault.copyWith(color: AppColors.dangerStart),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: 'الاسم الكامل',
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryAccent),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال الاسم';
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryAccent),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                              if (!val.contains('@')) return 'يرجى إدخال بريد إلكتروني صحيح';
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
                              labelText: 'رقم الهاتف (اختياري)',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryAccent),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: 'كلمة السر',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryAccent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'يرجى إدخال كلمة السر';
                              if (val.length < 6) return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
                              return null;
                            },
                          ),
                          SizedBox(height: 24.h),

                          // Register Button
                          ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleRegister,
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
                                : Text('إنشاء الحساب', style: AppStyles.buttonText.copyWith(color: Colors.white)),
                          ),
                          SizedBox(height: 16.h),

                          Row(
                            children: [
                              const Expanded(child: Divider(color: AppColors.borderLight)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text('أو', style: AppStyles.bodyMuted),
                              ),
                              const Expanded(child: Divider(color: AppColors.borderLight)),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Google Sign-In Button
                          OutlinedButton.icon(
                            onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                            icon: Icon(Icons.g_mobiledata, size: 28.sp, color: AppColors.primaryAccent),
                            label: Text('تسجيل بواسطة Google', style: AppStyles.labelBold),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              side: const BorderSide(color: AppColors.borderMedium),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('لديك حساب بالفعل؟ ', style: AppStyles.bodyMuted),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Text(
                                  'تسجيل الدخول',
                                  style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent),
                                ),
                              ),
                            ],
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
