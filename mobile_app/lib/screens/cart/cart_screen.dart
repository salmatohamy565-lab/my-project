import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/payment_methods_modal.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/product_details_modal.dart';
import '../../widgets/product_image_widget.dart';
import '../../models/order_model.dart';
import '../home/home_screen.dart';
import '../profile_screen.dart';

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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => ProductDetailsModal.show(context, product),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Row(
                                  children: [
                                    // Product Thumbnail using ProductImageWidget
                                    ProductImageWidget(
                                      imageUrl: product.imageUrl,
                                      baseUrl: authProvider.baseUrl,
                                      width: 64.w,
                                      height: 64.w,
                                      borderRadius: BorderRadius.circular(12.r),
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
                                          Row(
                                            children: [
                                              Text(
                                                '${product.price.toStringAsFixed(0)} ج.م',
                                                style: TextStyle(
                                                  color: AppColors.primaryAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                              SizedBox(width: 6.w),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryAccent.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.info_outline_rounded, color: AppColors.primaryAccent, size: 11.r),
                                                    SizedBox(width: 3.w),
                                                    Text(
                                                      'التفاصيل 📋',
                                                      style: TextStyle(
                                                        color: AppColors.primaryAccent,
                                                        fontSize: 10.sp,
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
                              ),
                            ),
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.primaryAccent, size: 20.r),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'لديك ${cartProvider.userLoyaltyPoints} نقطة ولاء (خصم 50 ج.م)',
                            style: TextStyle(color: AppColors.textMain, fontSize: 11.sp, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
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
                  Text('المجموع الإجمالي', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                  SizedBox(height: 2.h),
                  Text(
                    '${cartProvider.grandTotal.toStringAsFixed(0)} ج.م',
                    style: TextStyle(color: AppColors.primaryAccent, fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (cartProvider.items.isEmpty) return;

                    final authProvider = context.read<AuthProvider>();
                    final user = authProvider.currentUser;

                    final itemsSummaryStr = cartProvider.items
                        .map((i) => '${i.product.name} x${i.quantity}')
                        .join(' • ');

                    final productIdsStr = cartProvider.items
                        .map((i) => i.product.id)
                        .join(',');

                    final itemsDetails = cartProvider.items.map((i) => {
                      'id': i.product.id,
                      'name': i.product.name,
                      'price': i.product.price,
                      'quantity': i.quantity,
                      'image_url': i.product.imageUrl ?? '',
                      'description': i.product.description,
                    }).toList();

                    final cartProducts = cartProvider.items.map((i) => i.product).toList();
                    final grandTotal = cartProvider.grandTotal;

                    PaymentMethodsModal.show(
                      context,
                      productName: itemsSummaryStr,
                      productPrice: grandTotal,
                      onConfirmOrder: (String methodTitle, String senderInfo, dynamic proofFile, dynamic proofBytes, dynamic proofFileName) async {
                        try {
                          File? pFile;
                          Uint8List? pBytes;
                          String? pName;
                          if (proofFile is File) pFile = proofFile;
                          if (proofBytes is Uint8List) pBytes = proofBytes;
                          if (proofFileName is String) pName = proofFileName;

                          final res = await ApiService().createOrder(
                            productIds: productIdsStr,
                            itemsSummary: itemsSummaryStr,
                            itemsDetails: itemsDetails,
                            paymentMethod: methodTitle,
                            senderInfo: senderInfo,
                            totalPrice: grandTotal,
                            paymentProof: pFile,
                            paymentProofBytes: pBytes,
                            paymentProofName: pName,
                            userId: user?.id,
                            userName: user?.displayName ?? user?.name ?? user?.username,
                            userPhone: user?.phone,
                          );

                          if (res.statusCode == 201 && res.data != null && res.data['id'] != null) {
                            final createdId = res.data['id'];

                            if (context.mounted) {
                              context.read<OrderProvider>().registerCreatedOrderId(createdId);
                              context.read<OrderProvider>().fetchOrders(currentUser: user);
                            }

                            cartProvider.addEarnedPoints(grandTotal);
                            cartProvider.clearCart();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 تم إرسال الطلب وإيصال التحويل بنجاح! رقم الطلب: #$createdId', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: AppColors.successStart,
                                  duration: const Duration(seconds: 4),
                                ),
                              );

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            }

                            return true;
                          } else {
                            throw Exception('لم يُرجع السيرفر إشعار تأكيد وإنشاء للطلب');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final cleanMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '').trim();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ أثناء إرسال الطلب: $cleanMsg', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: AppColors.dangerStart,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                          return false;
                        }
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
