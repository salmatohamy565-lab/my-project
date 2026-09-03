import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/payment_methods_modal.dart';
import '../../widgets/product_details_modal.dart';
import '../../widgets/photo_block_pricing_widget.dart';
import '../../providers/auth_provider.dart';
import '../cart/cart_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  final String? initialSubCategory;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    this.initialSubCategory,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late String _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    _selectedSubCategory = widget.initialSubCategory ?? 'الكل';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  List<ProductModel> _getFilteredProducts(List<ProductModel> allProducts) {
    final cat = widget.category;
    final subcatList = cat.subCategoriesList;

    if (subcatList.isNotEmpty) {
      // Category has subcategories
      final subIds = subcatList.map((s) => s.id).toSet();
      final catSubProducts = allProducts.where((p) =>
        p.categoryId == cat.id ||
        (p.subcategoryId != null && subIds.contains(p.subcategoryId)) ||
        p.name.contains(cat.title) ||
        p.description.contains(cat.title)
      ).toList();

      if (_selectedSubCategory == 'الكل') {
        return catSubProducts;
      }

      final matchedSub = subcatList.firstWhere(
        (s) => s.name == _selectedSubCategory,
        orElse: () => SubcategoryModel(id: -1, categoryId: cat.id, name: _selectedSubCategory),
      );

      if (matchedSub.id != -1) {
        return allProducts.where((p) => p.subcategoryId == matchedSub.id).toList();
      }

      final cleanSub = _selectedSubCategory.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
      return catSubProducts.where((p) => p.name.contains(cleanSub) || p.description.contains(cleanSub)).toList();
    }

    // Category has NO subcategories -> filter by category_id directly
    return allProducts.where((p) =>
      p.categoryId == cat.id ||
      p.name.contains(cat.title) ||
      p.description.contains(cat.title)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isCustomer = currentUser == null || currentUser.isCustomer;

    final productProvider = context.watch<ProductProvider>();
    final allProducts = productProvider.products;
    final filtered = _getFilteredProducts(allProducts);
    final displayList = filtered;

    final subCats = widget.category.subCategories.isNotEmpty
        ? ['الكل', ...widget.category.subCategories]
        : <String>[];

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: 'قسم ${widget.category.title}'),

            // Scrollable Category Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  children: [
                    // Header Banner for Category
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      margin: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.category.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AppStyles.cardRadius,
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(widget.category.icon, color: Colors.white, size: 32.r),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category.title,
                                  style: AppStyles.titleMedium.copyWith(color: Colors.white, fontSize: 20.sp),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'تصفح أفضل منتجات وعروض قسم ${widget.category.title}',
                                  style: AppStyles.bodyMuted.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 12.sp),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Photo Block & Frames Pricing Table for Frames category
                    if (widget.category.title.contains('براويز') ||
                        widget.category.title.contains('فوتوبلوك') ||
                        widget.category.title.contains('تابلوهات')) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: PhotoBlockPricingWidget(
                          onSizeSelected: (type, size, price) {
                            final photoBlockProduct = ProductModel(
                              id: (DateTime.now().millisecondsSinceEpoch % 89999) + 10000,
                              name: '$type - مقاس $size',
                              description: 'نوع المنتج: $type | مقاس $size سم. طباعة حرارية عالية الدقة مع تغليف وحماية فاخرة.',
                              price: price,
                              categoryId: widget.category.id,
                              imageUrl: 'assets/product_images/frames.jpg',
                            );
                            ProductDetailsModal.show(context, photoBlockProduct);
                          },
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],

                    // Sub-categories Filter Chips if available (like for ورقيات)
                    if (subCats.isNotEmpty) ...[
                      Container(
                        height: 44.h,
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: subCats.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8.w),
                          itemBuilder: (context, index) {
                            final sub = subCats[index];
                            final isSelected = sub == _selectedSubCategory;

                            return ChoiceChip(
                              label: Text(
                                sub,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textMain,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13.sp,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primaryAccent,
                              backgroundColor: AppColors.cardBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primaryAccent : AppColors.borderLight,
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSubCategory = sub;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],

                    // Products Grid
                    productProvider.isLoading && allProducts.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
                          )
                        : displayList.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.h),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 48.r),
                                      SizedBox(height: 12.h),
                                      Text('لا توجد منتجات متوفرة حالياً لهذا القسم', style: AppStyles.bodyMuted),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: ScreenUtil().screenWidth > 600 ? 3 : 2,
                                  childAspectRatio: 0.58,
                                  crossAxisSpacing: 12.w,
                                  mainAxisSpacing: 12.h,
                                ),
                                itemCount: displayList.length,
                                itemBuilder: (context, index) {
                                  final product = displayList[index];
                                  final isBestSeller = index % 2 == 0;
                                  final discount = isBestSeller ? '15% OFF' : null;

                                  return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: AppStyles.cardRadius,
                                border: Border.all(color: AppColors.borderLight),
                                boxShadow: AppStyles.cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product image & Badges (Tap to open ProductDetailsModal)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => ProductDetailsModal.show(context, product),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Padding(
                                              padding: EdgeInsets.all(8.r),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12.r),
                                                child: _buildSmartImage(
                                                  product.imageUrl ?? widget.category.imageUrl,
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fallbackIcon: widget.category.icon,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (discount != null)
                                            Positioned(
                                              top: 8.h,
                                              right: 8.w,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  borderRadius: BorderRadius.circular(8.r),
                                                ),
                                                child: Text(
                                                  discount,
                                                  style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10.w),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () => ProductDetailsModal.show(context, product),
                                          child: Text(
                                            product.name,
                                            style: AppStyles.labelBold.copyWith(fontSize: 13.sp),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Builder(
                                          builder: (context) {
                                            final cartProvider = context.watch<CartProvider>();
                                            final itemIdx = cartProvider.items.indexWhere((it) => it.product.id == product.id);
                                            final inCartQty = itemIdx >= 0 ? cartProvider.items[itemIdx].quantity : 0;

                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  product.price <= 0 ? 'تواصل معنا' : '${product.price.toStringAsFixed(0)} ج.م',
                                                  style: TextStyle(
                                                    color: AppColors.primaryAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                                if (isCustomer) ...[
                                                  if (inCartQty == 0)
                                                    InkWell(
                                                      onTap: () {
                                                        cartProvider.addToCart(product);
                                                        Navigator.of(context).push(
                                                          MaterialPageRoute(builder: (_) => const CartScreen()),
                                                        );
                                                      },
                                                      borderRadius: BorderRadius.circular(10.r),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primaryAccent,
                                                          borderRadius: BorderRadius.circular(10.r),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppColors.primaryAccent.withOpacity(0.3),
                                                              blurRadius: 6.r,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16.r),
                                                            SizedBox(width: 3.w),
                                                            Icon(Icons.add, color: Colors.white, size: 15.r),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryAccent.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(10.r),
                                                        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () => cartProvider.updateQuantity(product.id, inCartQty - 1),
                                                            child: Padding(
                                                              padding: EdgeInsets.all(2.r),
                                                              child: Icon(
                                                                inCartQty > 1 ? Icons.remove : Icons.delete_outline,
                                                                color: inCartQty > 1 ? AppColors.primaryAccent : AppColors.dangerStart,
                                                                size: 16.r,
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                Navigator.of(context).push(
                                                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                                                );
                                                              },
                                                              child: Text(
                                                                '$inCartQty',
                                                                style: TextStyle(
                                                                  color: AppColors.primaryAccent,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13.sp,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () => cartProvider.updateQuantity(product.id, inCartQty + 1),
                                                            child: Padding(
                                                              padding: EdgeInsets.all(2.r),
                                                              child: Icon(Icons.add, color: AppColors.primaryAccent, size: 16.r),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: 'categories',
        isAdmin: false,
      ),
    );
  }

  Widget _buildSmartImage(String? imagePath, {BoxFit fit = BoxFit.contain, double? width, double? height, IconData? fallbackIcon}) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return _buildFallback(fallbackIcon);
    }
    final trimmedPath = imagePath.trim();

    // 1. Direct local asset image
    if (trimmedPath.startsWith('assets/')) {
      return Image.asset(
        trimmedPath,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildFallback(fallbackIcon),
      );
    }

    // 2. Network image or filename
    final filename = trimmedPath.split('/').last;
    final fullUrl = trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')
        ? trimmedPath
        : 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/$filename';

    return Image.network(
      fullUrl,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/product_images/$filename',
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildFallback(fallbackIcon),
      ),
    );
  }

  Widget _buildFallback(IconData? fallbackIcon) {
    if (widget.category.imageUrl.isNotEmpty) {
      if (widget.category.imageUrl.startsWith('assets/')) {
        return Image.asset(
          widget.category.imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(fallbackIcon),
        );
      } else {
        final catFilename = widget.category.imageUrl.split('/').last;
        final catUrl = widget.category.imageUrl.startsWith('http')
            ? widget.category.imageUrl
            : 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/$catFilename';
        return Image.network(
          catUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/product_images/$catFilename',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildPlaceholderIcon(fallbackIcon),
          ),
        );
      }
    }
    return _buildPlaceholderIcon(fallbackIcon);
  }

  Widget _buildPlaceholderIcon(IconData? icon) {
    return Container(
      color: Colors.white.withOpacity(0.06),
      child: Center(
        child: Icon(icon ?? Icons.style_rounded, color: AppColors.primaryAccent, size: 36.r),
      ),
    );
  }
}
