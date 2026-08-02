import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/radial_background.dart';
import '../widgets/animations.dart';
import 'admin/admin_dashboard.dart';
import 'employee/employee_dashboard.dart';
import 'products/public_catalog_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLogin();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('bolaSavedName');
    final savedPhone = prefs.getString('bolaSavedPhone');
    final savedEmail = prefs.getString('bolaSavedEmail');

    if (savedName != null) _nameController.text = savedName;
    if (savedPhone != null) _phoneController.text = savedPhone;
    if (savedEmail != null) _emailController.text = savedEmail;
  }

  Future<void> _handleEnter() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bolaSavedName', _nameController.text.trim());
    await prefs.setString('bolaSavedPhone', _phoneController.text.trim());
    await prefs.setString('bolaSavedEmail', _emailController.text.trim());

    if (!mounted) return;

    // Check if entered credentials match admin or employee login
    final authProvider = context.read<AuthProvider>();
    final username = _nameController.text.trim();
    final password = _passwordController.text;

    // Attempt backend login silently if password provided
    if (username.isNotEmpty && password.isNotEmpty) {
      final success = await authProvider.login(username, password, true);
      if (success && mounted) {
        final currentUser = authProvider.currentUser;
        if (currentUser != null && currentUser.isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
          return;
        } else if (currentUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
          );
          return;
        }
      }
    }

    // Default: Navigate directly to Public Catalog Screen with entered name
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PublicCatalogScreen(
          userName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'malakmoatasem0008780',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Image.asset(
                      'assets/LOGO_new_bola_designs_for_dark_cx.png',
                      height: 100.h,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/bola_logo.png',
                        height: 100.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'مرحباً بك في Bola Designs',
                      style: AppStyles.titleMedium.copyWith(fontSize: 20.sp),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'أدخل بياناتك للانتقال للصفحة الرئيسية',
                      style: AppStyles.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Input Form Card
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
                        // 1. الاسم (Full Name)
                        Text('الاسم', style: AppStyles.labelBold, textAlign: TextAlign.right),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textMain),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: 'أدخل الاسم بالكامل',
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال الاسم';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // 2. رقم الهاتف (Phone Number)
                        Text('رقم الهاتف', style: AppStyles.labelBold, textAlign: TextAlign.right),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textMain),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: 'أدخل رقم الهاتف',
                            prefixIcon: Icon(Icons.phone_android_outlined, color: AppColors.textMuted),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال رقم الهاتف';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // 3. البريد الإلكتروني (Email)
                        Text('البريد الإلكتروني', style: AppStyles.labelBold, textAlign: TextAlign.right),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textMain),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: 'أدخل البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال البريد الإلكتروني';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // 4. كلمة السر (Password)
                        Text('كلمة السر', style: AppStyles.labelBold, textAlign: TextAlign.right),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textMain),
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'أدخل كلمة السر',
                            prefixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted,
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
                        SizedBox(height: 24.h),

                        // Enter Button
                        AnimatedPressButton(
                          onTap: _handleEnter,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20.sp),
                                SizedBox(width: 10.w),
                                Text(
                                  'الدخول إلى الرئيسية',
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
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
