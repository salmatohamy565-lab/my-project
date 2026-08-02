import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/animations.dart';
import '../../widgets/payment_methods_modal.dart';
import '../../widgets/product_image_widget.dart';
import '../login_screen.dart';

class PublicCatalogScreen extends StatefulWidget {
  const PublicCatalogScreen({super.key});

  @override
  State<PublicCatalogScreen> createState() => _PublicCatalogScreenState();
}

class _PublicCatalogScreenState extends State<PublicCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchPublicProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final publicProducts = productProvider.publicProducts;

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            // Unified App Logo Bar with single glassmorphic Login button
            AppLogoBar(
              trailing: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 11.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.primaryAccent.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            color: AppColors.textMain,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'تسجيل الدخول',
                            style: AppStyles.labelBold.copyWith(
                              color: AppColors.textMain,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<ProductProvider>().fetchPublicProducts(),
                color: AppColors.primaryAccent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('معرض المنتجات', style: AppStyles.titleLarge),
                            SizedBox(height: 4.h),
                            Text(
                              'تصفح منتجاتنا وأسعارنا بكل حرية',
                              style: AppStyles.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Light Glassmorphism Brand Hero Card (Light & Soft for Eyes)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 20.r,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputBg,
                                        borderRadius: BorderRadius.circular(18.r),
                                        border: Border.all(
                                          color: AppColors.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/logo.svg',
                                        width: 44.w,
                                        height: 44.w,
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bola Designs',
                                            style: AppStyles.titleMedium.copyWith(
                                              fontSize: 18.sp,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'أفضل تصميمات الدعاية والإعلان بأسلوب عصري واحترافي لتجعل علامتك التجارية تتكلم.',
                                            style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: AppColors.borderLight, height: 24, thickness: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryAccent.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone, color: AppColors.primaryAccent, size: 14),
                                          SizedBox(width: 6.w),
                                          Text(
                                            '01222856926',
                                            style: AppStyles.bodyDefault.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningStart.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: AppColors.warningStart, size: 14),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'تصميم هوية، إعلانات رقمية، مطبوعات',
                                            style: AppStyles.bodyMuted.copyWith(
                                              fontSize: 10.sp,
                                              color: AppColors.textMain,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Products Section
                      if (productProvider.isLoading && publicProducts.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primaryAccent),
                          ),
                        )
                      else if (publicProducts.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: AppStyles.cardRadius,
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.storefront, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                              SizedBox(height: 12.h),
                              Text('لا توجد منتجات معروضة حالياً', style: AppStyles.bodyMuted),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: publicProducts.length,
                          itemBuilder: (context, index) {
                            final p = publicProducts[index];
                            final fullImageUrl = p.getFullImageUrl(authProvider.baseUrl);

                            return AnimatedEntrance(
                              delay: Duration(milliseconds: 250 + (index * 90)),
                              child: Container(
                               margin: EdgeInsets.only(bottom: 18.h),
                               decoration: BoxDecoration(
                                 color: AppColors.cardBg,
                                 border: Border.all(color: AppColors.borderLight, width: 1.5),
                                 borderRadius: BorderRadius.circular(24.r),
                                 boxShadow: AppStyles.cardShadow,
                               ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ProductImageWidget(
                                    imageUrl: p.imageUrl,
                                    baseUrl: authProvider.baseUrl,
                                    height: 160.h,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16.w),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: AppStyles.titleMedium.copyWith(
                                                  fontSize: 16.sp,
                                                  color: AppColors.textMain,
                                                ),
                                              ),
                                              SizedBox(height: 6.h),
                                              Text(
                                                p.description.isEmpty ? 'بدون وصف' : p.description,
                                                style: AppStyles.bodyMuted,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                            borderRadius: BorderRadius.circular(12.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${p.price.toStringAsFixed(2)} ج.م',
                                            style: AppStyles.labelBold.copyWith(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(color: AppColors.borderLight, height: 16),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          PaymentMethodsModal.show(
                                            context,
                                            productName: p.name,
                                            productPrice: p.price,
                                            onConfirmOrder: (methodTitle, senderInfo, [proofFile]) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('✓ تم استلام طلبك لـ "${p.name}" عبر $methodTitle بنجاح!', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  backgroundColor: AppColors.successStart,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 16),
                                        label: Text('طلب ودفع (كاش/انستاباي)', style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 12.sp)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondaryAccent,
                                          elevation: 2,
                                          padding: EdgeInsets.symmetric(vertical: 8.h),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                             ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
