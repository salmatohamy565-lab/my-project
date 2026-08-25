import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/api_service.dart';
import 'payment_methods_modal.dart';
import '../screens/profile_screen.dart';
import 'product_image_widget.dart';
import 'photo_block_pricing_widget.dart';

class ProductDetailsModal {
  static void show(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductDetailsBottomSheet(product: product),
    );
  }
}

class _ProductDetailsBottomSheet extends StatefulWidget {
  final ProductModel product;

  const _ProductDetailsBottomSheet({required this.product});

  @override
  State<_ProductDetailsBottomSheet> createState() => _ProductDetailsBottomSheetState();
}

class _ProductDetailsBottomSheetState extends State<_ProductDetailsBottomSheet> {
  int _quantity = 1;
  late String _displayName;
  late double _displayPrice;

  @override
  void initState() {
    super.initState();
    _displayName = widget.product.name;
    _displayPrice = widget.product.price;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final activeProduct = ProductModel(
      id: product.id,
      name: _displayName,
      description: product.description,
      price: _displayPrice,
      imageUrl: product.imageUrl,
      categoryId: product.categoryId,
      createdAt: product.createdAt,
    );
    final authProvider = context.watch<AuthProvider>();
    final baseUrl = authProvider.baseUrl;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24.r,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle & Close Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Product Image Display with Zoom capability
              GestureDetector(
                onTap: () {
                  final fullImgUrl = activeProduct.getFullImageUrl(baseUrl);
                  if (fullImgUrl != null) {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.all(12.w),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            InteractiveViewer(
                              child: ProductImageWidget(
                                imageUrl: activeProduct.imageUrl,
                                baseUrl: baseUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12.r,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ProductImageWidget(
                    imageUrl: activeProduct.imageUrl,
                    baseUrl: baseUrl,
                    height: 300.h,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Product Title & Price Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeProduct.name,
                          style: AppStyles.titleMedium.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Bola Designs • منتج مخصص 🎨',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      activeProduct.price <= 0 ? 'تواصل معنا' : '${(activeProduct.price * _quantity).toStringAsFixed(0)} ج.م',
                      style: AppStyles.labelBold.copyWith(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              const Divider(color: AppColors.borderLight),
              SizedBox(height: 12.h),

              // Description & Specifications Section
              Text(
                'الوصف والمواصفات الكاملة 📋',
                style: AppStyles.titleSmall.copyWith(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  activeProduct.description.isNotEmpty
                      ? activeProduct.description
                      : 'منتج عالي الجودة مصمم ومطبوع بعناية فائقة في مطابع بولا ديزاينز باستخدام أفضل المواد الخام.',
                  style: AppStyles.bodyDefault.copyWith(
                    color: AppColors.textMain,
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Feature Badges Grid
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: const [
                  _SpecBadge(icon: Icons.high_quality_rounded, label: 'خامات فاخرة عالية الجودة'),
                  _SpecBadge(icon: Icons.brush_rounded, label: 'طباعة وحفر ليزر دقيق'),
                  _SpecBadge(icon: Icons.local_shipping_rounded, label: 'توصيل سريع لجميع المحافظات'),
                  _SpecBadge(icon: Icons.card_giftcard_rounded, label: 'تغليف هدايا احترافي'),
                ],
              ),
              SizedBox(height: 16.h),

              // Photo Block & Frames Price Matrix
              if (activeProduct.name.contains('برواز') ||
                  activeProduct.name.contains('فوتوبلوك') ||
                  activeProduct.name.contains('جامبو') ||
                  activeProduct.name.contains('مسطرة') ||
                  activeProduct.categoryId == 'frames') ...[
                PhotoBlockPricingWidget(
                  onSizeSelected: (type, size, price) {
                    setState(() {
                      _displayName = '$type - مقاس $size';
                      _displayPrice = price;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ تم تحديد المقاس: $size بسعر $price ج.م'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppColors.primaryAccent,
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.h),
              ],

              // Quantity Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الكمية المطلوبة:', style: AppStyles.labelBold.copyWith(fontSize: 14.sp)),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                          icon: const Icon(Icons.remove, color: AppColors.textMain, size: 18),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            '$_quantity',
                            style: AppStyles.labelBold.copyWith(fontSize: 15.sp),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add, color: AppColors.primaryAccent, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Action Buttons: Cart & Direct Buy
              Row(
                children: [
                  // Cart Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final cartProvider = context.read<CartProvider>();
                        for (int i = 0; i < _quantity; i++) {
                          cartProvider.addToCart(activeProduct);
                        }
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🛒 تم إضافة "$_quantity x ${activeProduct.name}" إلى السلة بنجاح!'),
                            backgroundColor: AppColors.primaryAccent,
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryAccent, size: 18),
                      label: Text('إضافة للسلة', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent, fontSize: 13.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent.withOpacity(0.12),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          side: BorderSide(color: AppColors.primaryAccent.withOpacity(0.4)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Direct Checkout Button
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final authProvider = context.read<AuthProvider>();
                        final orderProvider = context.read<OrderProvider>();
                        final user = authProvider.currentUser;
                        final totalPrice = activeProduct.price * _quantity;
                        final itemsSummaryStr = '${activeProduct.name} x$_quantity';

                        final itemsDetails = [
                          {
                            'id': activeProduct.id,
                            'name': activeProduct.name,
                            'price': activeProduct.price,
                            'quantity': _quantity,
                            'image_url': activeProduct.imageUrl ?? '',
                            'description': activeProduct.description,
                          }
                        ];

                        Navigator.of(context).pop();

                        PaymentMethodsModal.show(
                          context,
                          productName: itemsSummaryStr,
                          productPrice: totalPrice,
                          onConfirmOrder: (String methodTitle, String senderInfo, dynamic proofFile, dynamic proofBytes, dynamic proofFileName) async {
                            try {
                              final newOrderId = DateTime.now().millisecondsSinceEpoch % 100000;
                              final localOrder = OrderModel(
                                id: newOrderId,
                                userId: user?.id ?? 0,
                                customerName: user?.displayName ?? user?.name ?? user?.username ?? 'عميل',
                                customerPhone: user?.phone ?? '01000000000',
                                productIds: activeProduct.id.toString(),
                                itemsSummary: itemsSummaryStr,
                                products: [activeProduct],
                                status: 'pending_approval',
                                totalPrice: totalPrice,
                                paymentMethod: methodTitle,
                                createdAt: DateTime.now(),
                              );

                              if (context.mounted) {
                                orderProvider.addLocalOrder(localOrder);
                              }

                              File? pFile;
                              Uint8List? pBytes;
                              String? pName;
                              if (proofFile is File) pFile = proofFile;
                              if (proofBytes is Uint8List) pBytes = proofBytes;
                              if (proofFileName is String) pName = proofFileName;

                              final res = await ApiService().createOrder(
                                productIds: activeProduct.id,
                                itemsSummary: itemsSummaryStr,
                                itemsDetails: itemsDetails,
                                paymentMethod: methodTitle,
                                senderInfo: senderInfo,
                                totalPrice: totalPrice,
                                paymentProof: pFile,
                                paymentProofBytes: pBytes,
                                paymentProofName: pName,
                                userId: user?.id,
                                userName: user?.displayName ?? user?.name ?? user?.username,
                                userPhone: user?.phone,
                              );

                              if (context.mounted) {
                                if (res.data != null && res.data['id'] != null) {
                                  orderProvider.registerCreatedOrderId(res.data['id']);
                                }
                                orderProvider.fetchOrders(currentUser: user);
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 تم إرسال الطلب وإيصال التحويل بنجاح! تم إرساله للأدمن 📋', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                                    backgroundColor: AppColors.successStart,
                                    duration: Duration(seconds: 4),
                                  ),
                                );

                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              }
                              return true;
                            } catch (e) {
                              print('[ORDER CREATION NOTICE] $e');
                              rethrow;
                            }
                          },
                        );
                      },
                      icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                      label: Text('اطلب الآن', style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 13.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryAccent,
                        elevation: 3,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryAccent, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(color: AppColors.textMain, fontSize: 11.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
