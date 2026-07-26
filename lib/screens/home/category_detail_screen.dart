import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/payment_methods_modal.dart';

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
    if (widget.category.id == 'paperwork') {
      if (_selectedSubCategory == 'الكل') {
        return allProducts;
      }
      return allProducts.where((p) =>
        p.name.contains(_selectedSubCategory) || p.description.contains(_selectedSubCategory)
      ).toList();
    }
    
    // Filter products matching category name or keywords
    return allProducts.where((p) =>
      p.name.contains(widget.category.title) || p.description.contains(widget.category.title)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final allProducts = productProvider.products;
    final filtered = _getFilteredProducts(allProducts);
    final displayList = filtered.isEmpty ? allProducts : filtered;

    final subCats = widget.category.subCategories.isNotEmpty
        ? ['الكل', ...widget.category.subCategories]
        : <String>[];

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: 'قسم ${widget.category.title}'),

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
            Expanded(
              child: productProvider.isLoading && allProducts.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                  : displayList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 48.r),
                              SizedBox(height: 12.h),
                              Text('لا توجد منتجات متوفرة حالياً لهذا القسم', style: AppStyles.bodyMuted),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ScreenUtil().screenWidth > 600 ? 3 : 2,
                            childAspectRatio: 0.72,
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
                                  // Product image & Badges
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                                          child: _buildSmartImage(
                                            product.imageUrl ?? widget.category.imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fallbackIcon: widget.category.icon,
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
                                  Padding(
                                    padding: EdgeInsets.all(10.w),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: AppStyles.labelBold.copyWith(fontSize: 13.sp),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${product.price.toStringAsFixed(0)} ج.م',
                                              style: TextStyle(
                                                color: AppColors.primaryAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                PaymentMethodsModal.show(
                                                  context,
                                                  productName: product.name,
                                                  productPrice: product.price,
                                                  onConfirmOrder: (methodTitle, senderInfo, [proofFile]) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('✓ تم طلب "${product.name}" بنجاح!'),
                                                        backgroundColor: AppColors.successStart,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(6.r),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryAccent,
                                                  borderRadius: BorderRadius.circular(10.r),
                                                ),
                                                child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 16.r),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  Widget _buildSmartImage(String? imagePath, {BoxFit fit = BoxFit.cover, double? width, double? height, IconData? fallbackIcon}) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholderIcon(fallbackIcon);
    }
    if (imagePath.startsWith('assets/')) {
      final filename = imagePath.split('/').last;
      final serverUrl = 'http://127.0.0.1:5001/static/product_images/$filename';
      return Image.network(
        serverUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Image.asset(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(fallbackIcon),
        ),
      );
    }
    final fullUrl = imagePath.startsWith('http') ? imagePath : ApiService().baseUrl + imagePath;
    return Image.network(
      fullUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(fallbackIcon),
    );
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
