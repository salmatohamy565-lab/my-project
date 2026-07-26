import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/radial_background.dart';
import 'login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'employee/employee_dashboard.dart';
import 'products/products_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo center → corner animation
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Alignment> _logoAlignment;

  // Progress bar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  bool _isNavigated = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // ── Logo animation (0 → 1200ms) ──
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 0.38).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
      ),
    );

    _logoAlignment = AlignmentTween(
      begin: Alignment.center,
      end: Alignment.topLeft,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
      ),
    );

    // ── Progress bar (starts after logo settles) ──
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_progressController)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleNavigation();
        }
      });

    // Sequence: show logo → animate it → show rest
    _logoController.forward().then((_) {
      if (mounted) {
        setState(() => _showContent = true);
        _progressController.forward();
      }
    });

    _logoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    if (_isNavigated) return;
    _isNavigated = true;

    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = await authProvider.checkAuth();

    if (!mounted) return;

    if (isAuthenticated) {
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
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: RadialBackground(
        child: Stack(
          children: [
            // ── Main content (fades in after logo settles) ──
            AnimatedOpacity(
              opacity: _showContent ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 80.h), // space for logo in corner
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 32.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 8.h),
                          Text(
                            'مرحباً بك في نظام Bola Designs',
                            style: AppStyles.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'نجهز لك واجهة احترافية لإدارة المهام والموظفين.',
                            style: AppStyles.bodyDefault
                                .copyWith(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32.h),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999.r),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: AppColors.borderLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryAccent),
                              minHeight: 6.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),

            // ── Animated Logo ──
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Align(
                  alignment: _logoAlignment.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12.w * _logoController.value,
                        top: _logoController.isCompleted
                            ? MediaQuery.of(context).padding.top + 7.h
                            : 0,
                      ),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        alignment: _logoController.isCompleted
                            ? Alignment.topLeft
                            : Alignment.center,
                        child: SvgPicture.asset(
                          'assets/logo2.svg',
                          width: screenWidth * 0.65,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
