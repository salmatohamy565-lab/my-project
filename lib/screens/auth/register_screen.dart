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
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();

    final rawInput = _usernameController.text.trim();
    final usernameToUse = rawInput.contains('@')
        ? AuthProvider.extractUsernameFromEmail(rawInput)
        : rawInput;

    final success = await authProvider.passwordlessRegister(
      usernameToUse,
      _phoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح!'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
      } else {
        final err = authProvider.errorMessage ?? 'فشل إنشاء الحساب، يرجى التأكد من البيانات والاتصال بالشبكة';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✕ $err'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
                            'قم بإنشاء حسابك بسرعة باستعمال الاسم ورقم الهاتف',
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

                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: AppColors.textMain),
                            decoration: const InputDecoration(
                              labelText: 'اسم المستخدم',
                              hintText: 'أدخل اسم المستخدم أو اسمك',
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryAccent),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال اسم المستخدم';
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),

                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: AppColors.textMain),
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              hintText: 'أدخل رقم الهاتف الخاص بك',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryAccent),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'يرجى إدخال رقم الهاتف';
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
