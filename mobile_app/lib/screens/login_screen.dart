import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/radial_background.dart';
import '../widgets/animations.dart';
import 'admin/admin_dashboard.dart';
import 'employee/employee_dashboard.dart';
import 'products/products_screen.dart';
import 'home/home_screen.dart';
import 'auth/forget_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('bolaRememberedUsername');
    final savedRemember = prefs.getBool('bolaRememberMe') ?? false;

    if (savedUsername != null && savedRemember) {
      setState(() {
        _usernameController.text = savedUsername;
        _rememberMe = savedRemember;
      });
    }
  }

  Future<void> _saveLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('bolaRememberedUsername', _usernameController.text.trim());
      await prefs.setBool('bolaRememberMe', true);
    } else {
      await prefs.remove('bolaRememberedUsername');
      await prefs.setBool('bolaRememberMe', false);
    }
  }



  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final rawInput = _usernameController.text.trim();
    final usernameToUse = rawInput.contains('@')
        ? AuthProvider.extractUsernameFromEmail(rawInput)
        : rawInput;

    final success = await authProvider.phoneLogin(
      usernameToUse,
      _phoneController.text.trim(),
      _rememberMe,
    );

    if (success && mounted) {
      await _saveLoginCredentials();
      final user = authProvider.currentUser;
      Widget targetScreen;
      if (user != null && user.isAdmin) {
        targetScreen = const AdminDashboard();
      } else if (user != null && user.isEmployee) {
        targetScreen = ProductsScreen();
      } else {
        targetScreen = const HomeScreen();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } else if (!success && mounted) {
      final err = authProvider.errorMessage ?? 'اسم المستخدم أو رقم الهاتف غير صحيح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✕ $err', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.dangerStart,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: RadialBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.h),

              // Logo + Header
              AnimatedEntrance(
                delay: const Duration(milliseconds: 80),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/logo2.svg',
                      width: 110.w,
                      height: 110.w,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => SvgPicture.asset(
                        'assets/logo.svg',
                        width: 110.w,
                        height: 110.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'إنشاء حساب',
                      style: AppStyles.titleMedium.copyWith(fontSize: 22.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'ادخل اسمك ورقم هاتفك للدخول إلى الحساب.',
                      style: AppStyles.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),

              // Login Card
              AnimatedEntrance(
                delay: const Duration(milliseconds: 200),
                slideOffset: 30,
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
                        if (authProvider.errorMessage != null && authProvider.errorMessage!.trim().isNotEmpty) ...[
                          AnimatedEntrance(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: AppColors.dangerStart.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: const Border(
                                  right: BorderSide(color: AppColors.dangerStart, width: 4),
                                ),
                              ),
                              child: Text(
                                authProvider.errorMessage!,
                                style: AppStyles.bodyDefault.copyWith(
                                  color: AppColors.dangerStart,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                        Text('اسم المستخدم أو الاسم', style: AppStyles.labelBold, textAlign: TextAlign.right),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: AppColors.textMain),
                          textAlign: TextAlign.right,
                          onChanged: (_) {
                            if (authProvider.errorMessage != null) {
                              authProvider.clearError();
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'أدخل الاسم الثلاثي (أو اسم المستخدم)',
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم المستخدم أو الاسم';
                            }
                            return null;
                          },

                        ),


                        SizedBox(height: 20.h),
                        Text('رقم الهاتف (اختياري)', style: AppStyles.labelBold, textAlign: TextAlign.right),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textMain),
                          textAlign: TextAlign.right,
                          onChanged: (_) {
                            if (authProvider.errorMessage != null) {
                              authProvider.clearError();
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'أدخل رقم الهاتف (اختياري)',
                            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textMuted),
                          ),
                          validator: (value) {
                            return null;
                          },
                        ),

                        SizedBox(height: 12.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.primaryAccent,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              onChanged: (value) => setState(() {
                                _rememberMe = value ?? false;
                              }),
                            ),
                            Text('تذكرني', style: AppStyles.bodyDefault),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // Login button
                        AnimatedPressButton(
                          onTap: authProvider.isLoading ? null : _handleLogin,
                          child: Container(
                            height: 54.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.primaryGradient,
                              ),
                              borderRadius: AppStyles.buttonRadius,
                              boxShadow: AppStyles.buttonShadow,
                            ),
                            child: authProvider.isLoading
                                ? SizedBox(
                                    height: 22.w,
                                    width: 22.w,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, color: Colors.white, size: 20.sp),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'إنشاء حساب',
                                        style: AppStyles.labelBold.copyWith(
                                          fontSize: 16.sp,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
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
              SizedBox(height: 16.h),

            ],
          ),
        ),
      ),
    );
  }
}
