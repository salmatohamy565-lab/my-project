import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_logo_bar.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeSent = false;
  String? _demoCode;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال بريد إلكتروني صحيح')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final code = await authProvider.forgetPassword(email);

    if (code != null && mounted) {
      setState(() {
        _codeSent = true;
        if (code != 'OK') _demoCode = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال كود الاستعادة! (الكود للتجربة: ${_demoCode ?? 'تفقد البريد'})'),
          backgroundColor: AppColors.emeraldGreen,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _handleResetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;

    if (code.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال جميع البيانات')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(email, code, newPassword);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إعادة تعيين كلمة السر بنجاح! يمكنك الدخول الآن.'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
      Navigator.of(context).pop();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'استعادة كلمة السر',
                          style: AppStyles.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _codeSent
                              ? 'أدخل الكود المرسل لبريدك الإلكتروني وكلمة السر الجديدة'
                              : 'أدخل بريدك الإلكتروني لإرسال كود استعادة كلمة السر',
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

                        if (!_codeSent) ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryAccent),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleSendCode,
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
                                : Text('إرسال كود التعيين', style: AppStyles.buttonText.copyWith(color: Colors.white)),
                          ),
                        ] else ...[
                          if (_demoCode != null) ...[
                            Container(
                              padding: EdgeInsets.all(10.w),
                              margin: EdgeInsets.only(bottom: 14.h),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '💡 كود الاستعادة للتجربة المباشرة: $_demoCode',
                                style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'كود الاستعادة (6 أرقام)',
                              prefixIcon: Icon(Icons.pin, color: AppColors.primaryAccent),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'كلمة السر الجديدة',
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryAccent),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            ),
                            child: authProvider.isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text('تأكيد كلمة السر الجديدة', style: AppStyles.buttonText),
                          ),
                        ],

                        SizedBox(height: 16.h),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'إلغاء والعودة لتسجيل الدخول',
                            style: AppStyles.bodyMuted.copyWith(color: AppColors.primaryAccent),
                          ),
                        ),
                      ],
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
