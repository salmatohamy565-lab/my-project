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
import 'auth/register_screen.dart';
import 'auth/forget_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

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
    _passwordController.dispose();
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

  void _showApiSettingsDialog() {
    final authProvider = context.read<AuthProvider>();
    final controller = TextEditingController(text: authProvider.baseUrl);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text(
            'إعدادات الاتصال بالخادم',
            style: AppStyles.titleSmall,
            textAlign: TextAlign.right,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أدخل عنوان خادم API الخاص بـ Flask:',
                style: AppStyles.bodyMuted,
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 12.h),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'https://bola-designs-backend.onrender.com',
                  ),
                  style: const TextStyle(color: AppColors.textMain),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: AppStyles.labelBold.copyWith(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  await authProvider.updateBaseUrl(newUrl);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تحديث عنوان الخادم إلى: $newUrl',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: AppColors.successStart,
                      ),
                    );
                  }
                }
              },
              child: Text('حفظ', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
      _rememberMe,
    );

    if (success && mounted) {
      await _saveLoginCredentials();
      final user = authProvider.currentUser;
      Widget targetScreen;
      if (user != null && user.isAdmin) {
        targetScreen = const AdminDashboard();
      } else if (user != null && user.isEmployee) {
        targetScreen = const EmployeeDashboard();
      } else {
        targetScreen = const HomeScreen();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    }
  }

  void _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();

    if (success && mounted) {
      final user = authProvider.currentUser;
      Widget targetScreen;
      if (user != null && user.isAdmin) {
        targetScreen = const AdminDashboard();
      } else if (user != null && user.isEmployee) {
        targetScreen = const EmployeeDashboard();
      } else {
        targetScreen = const HomeScreen();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => targetScreen),
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
              // Settings button
              AnimatedEntrance(
                delay: const Duration(milliseconds: 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: AppColors.textMuted, size: 22.sp),
                    onPressed: _showApiSettingsDialog,
                  ),
                ),
              ),
              SizedBox(height: 10.h),

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
                      'مرحباً بك في Bola Designs',
                      style: AppStyles.titleMedium.copyWith(fontSize: 20.sp),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'ادخل بياناتك للوصول إلى حسابك والمنتجات.',
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
                        Text('اسم المستخدم أو البريد الإلكتروني', style: AppStyles.labelBold, textAlign: TextAlign.right),
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
                            hintText: 'أدخل اسم المستخدم أو البريد الإلكتروني',
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم المستخدم أو البريد';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),
                        Text('كلمة السر', style: AppStyles.labelBold, textAlign: TextAlign.right),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textMain),
                          textAlign: TextAlign.right,
                          onChanged: (_) {
                            if (authProvider.errorMessage != null) {
                              authProvider.clearError();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'أدخل كلمة السر',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.primaryAccent,
                              ),
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال كلمة السر';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
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
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                                );
                              },
                              child: Text(
                                'نسيت كلمة السر؟',
                                style: AppStyles.bodyMuted.copyWith(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
                                        'تسجيل الدخول',
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
                            Text('ليس لديك حساب؟ ', style: AppStyles.bodyMuted),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: Text(
                                'إنشاء حساب جديد',
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
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
