import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/payment_methods_modal.dart';
import '../../widgets/radial_background.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final cartItems = cartProvider.items;

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: user?.username ?? 'سلة الطلبات'),

            // Page Header Title
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(Icons.shopping_cart_rounded, color: AppColors.primaryAccent, size: 24.r),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('سلة الطلبات', style: AppStyles.titleMedium.copyWith(fontSize: 18.sp)),
                          Text(
                            '${cartProvider.itemCount} منتجات في السلة',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (cartItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => cartProvider.clearCart(),
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.dangerStart, size: 18),
                      label: const Text('إفرغ السلة', style: TextStyle(color: AppColors.dangerStart)),
                    ),
                ],
              ),
            ),

            // Cart Items List
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_shopping_cart_outlined, color: AppColors.textMuted, size: 64.r),
                          SizedBox(height: 16.h),
                          Text('سلة الطلبات فارغة حالياً', style: AppStyles.titleSmall),
                          SizedBox(height: 8.h),
                          Text(
                            'تصفح منتجات Bola Designs وأضف ما تحتاجه للسلة بسهولة!',
                            style: AppStyles.bodyMuted,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = item.product;

                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8.r,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Product Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: SizedBox(
                                  width: 64.w,
                                  height: 64.w,
                                  child: product.imageUrl != null
                                      ? Image.network(
                                          product.getFullImageUrl(ApiService().baseUrl)!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                                        )
                                      : _buildThumbPlaceholder(),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: AppStyles.labelBold.copyWith(fontSize: 14.sp),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '${product.price.toStringAsFixed(0)} ج.م',
                                      style: TextStyle(
                                        color: AppColors.primaryAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Controls (+ / -)
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => cartProvider.updateQuantity(product.id, item.quantity - 1),
                                    icon: Icon(
                                      item.quantity > 1 ? Icons.remove_circle_outline : Icons.delete_outline,
                                      color: item.quantity > 1 ? AppColors.textMuted : AppColors.dangerStart,
                                      size: 22.r,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: AppStyles.labelBold.copyWith(fontSize: 15.sp),
                                  ),
                                  IconButton(
                                    onPressed: () => cartProvider.updateQuantity(product.id, item.quantity + 1),
                                    icon: Icon(Icons.add_circle_outline, color: AppColors.primaryAccent, size: 22.r),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Summary & Loyalty Points Card (Bottom)
            if (cartItems.isNotEmpty) _buildCheckoutCard(context, cartProvider),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentRoute: 'cart',
        isAdmin: user?.isAdmin ?? false,
      ),
    );
  }

  Widget _buildCheckoutCard(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16.r,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Loyalty Points Redemption Option
          if (cartProvider.userLoyaltyPoints >= 100 && !cartProvider.pointsRedeemed)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: AppColors.primaryAccent, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        'لديك ${cartProvider.userLoyaltyPoints} نقطة ولاء (خصم 50 ج.م)',
                        style: TextStyle(color: AppColors.textMain, fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final success = cartProvider.redeemLoyaltyPoints();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 تم تطبيق خصم النقاط بنجاح!'),
                            backgroundColor: AppColors.successStart,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text('استبدل خصم', style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                  ),
                ],
              ),
            ),

          if (cartProvider.pointsRedeemed)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الخصم المطبق (نقاط الولاء):', style: TextStyle(color: AppColors.successStart, fontSize: 12.sp)),
                  Text('- ${cartProvider.appliedDiscount.toStringAsFixed(0)} ج.م', style: TextStyle(color: AppColors.successStart, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                ],
              ),
            ),

          // Total price & Checkout button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المجموع الإجمالي', style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
                  SizedBox(height: 2.h),
                  Text(
                    '${cartProvider.grandTotal.toStringAsFixed(0)} ج.م',
                    style: TextStyle(color: AppColors.primaryAccent, fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  PaymentMethodsModal.show(
                    context,
                    productName: 'طلب سلة Bola Designs (${cartProvider.itemCount} منتجات)',
                    productPrice: cartProvider.grandTotal,
                    onConfirmOrder: (methodTitle, senderInfo, [proofFile]) {
                      cartProvider.addEarnedPoints(cartProvider.grandTotal);
                      cartProvider.clearCart();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ تم تأكيد الطلب بنجاح عبر $methodTitle!'),
                          backgroundColor: AppColors.successStart,
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text('إتمام الطلب الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.06),
      child: Center(
        child: Icon(Icons.style_rounded, color: AppColors.textMuted, size: 24.r),
      ),
    );
  }
}
