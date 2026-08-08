import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/payment_methods_modal.dart';
import '../../widgets/product_image_widget.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  CategoryModel? _selectedCategory;
  File? _selectedImage;
  int? _editingProductId;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _editingProductId = null;
      _selectedImage = null;
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _showForm = false;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final priceStr = _priceController.text.trim();

    if (name.isEmpty || priceStr.isEmpty) {
      _showSnackbar('الاسم والسعر مطلوبة لحفظ المنتج', Colors.red);
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null) {
      _showSnackbar('السعر يجب أن يكون رقماً صحيحاً', Colors.red);
      return;
    }

    final categoryId = _selectedCategory?.id;
    final productProvider = context.read<ProductProvider>();
    bool success;

    if (_editingProductId != null) {
      success = await productProvider.editProduct(
        _editingProductId!,
        name,
        desc,
        price,
        _selectedImage,
        categoryId: categoryId,
      );
    } else {
      success = await productProvider.addProduct(
        name,
        desc,
        price,
        _selectedImage,
        categoryId: categoryId,
      );
    }

    if (success) {
      _showSnackbar('✓ تم حفظ المنتج بنجاح', AppColors.successStart);
      _resetForm();
    } else {
      final error = productProvider.errorMessage ?? 'فشل حفظ المنتج';
      _showSnackbar(error, Colors.red);
    }
  }

  void _startEdit(ProductModel product) {
    setState(() {
      _editingProductId = product.id;
      _nameController.text = product.name;
      _descController.text = product.description;
      _priceController.text = product.price.toStringAsFixed(2);
      _selectedImage = null;
      _showForm = true;
    });
  }

  Future<void> _deleteProduct(int productId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.loginCardBg,
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: const Text('هل تريد حذف هذا المنتج نهائياً؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final productProvider = context.read<ProductProvider>();
              final success = await productProvider.deleteProduct(productId);
              if (success) {
                _showSnackbar('✓ تم حذف المنتج بنجاح', AppColors.successStart);
              } else {
                final error = productProvider.errorMessage ?? 'فشل حذف المنتج';
                _showSnackbar(error, Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerStart),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    
    final currentUser = authProvider.currentUser;
    final products = productProvider.products;
    final isAdmin = currentUser?.isAdmin ?? false;
    final isCustomer = currentUser == null || currentUser.isCustomer;

    return Scaffold(
      key: _scaffoldKey,
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: currentUser?.username ?? 'المستخدم'),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<ProductProvider>().fetchProducts(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Navigation Header
                      _buildHeader(isAdmin),
                      SizedBox(height: 20.h),

                      // Brand Hero card
                      _buildBrandHeroCard(),
                      SizedBox(height: 20.h),

                      // Category Grid OR Category Detail Page
                      if (_selectedCategory == null)
                        _buildCategoryGrid(products, isAdmin)
                      else
                        _buildCategoryDetailPage(products, authProvider.baseUrl, isAdmin, isCustomer, productProvider),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentRoute: 'products',
        isAdmin: isAdmin,
      ),
    );
  }

  Widget _buildHeader(bool isAdmin) {
    if (_selectedCategory == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('منتجاتي حسب الأقسام', style: AppStyles.titleLarge),
                Text(
                  'اختر القسم لعرض وإدارة منتجاته أو إضافة منتج جديد داخله',
                  style: AppStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedCategory = null;
              _resetForm();
            });
          },
          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryAccent),
          tooltip: 'رجوع للأقسام',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.cardBg,
            padding: EdgeInsets.all(10.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCategory!.title,
                style: AppStyles.titleMedium.copyWith(fontSize: 17.sp, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'قسم ${_selectedCategory!.title}',
                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isAdmin)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showForm = !_showForm;
                if (!_showForm) _resetForm();
              });
            },
            icon: Icon(_showForm ? Icons.close : Icons.add, color: Colors.white, size: 16),
            label: Text(
              _showForm ? 'إلغاء' : '+ منتج',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _showForm ? Colors.red.shade600 : AppColors.secondaryAccent,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
      ],
    );
  }

  Widget _buildBrandHeroCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                ),
                child: Image.asset(
                  'assets/bola_logo.png',
                  width: 46.w,
                  height: 46.w,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bola Designs', style: AppStyles.titleMedium),
                    Text(
                      'إدارة واستعراض المنتجات المخصصة لكل قسم في الدعاية والإعلان.',
                      style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, color: AppColors.primaryAccent, size: 16),
                  SizedBox(width: 6.w),
                  Text('0122856926', style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.successStart, size: 16),
                  SizedBox(width: 6.w),
                  Text('خدمة احترافية وتوصيل سريع', style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<ProductModel> products, bool isAdmin) {
    final categories = CategoryModel.defaultCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تصفح أقسام المنتجات (${categories.length})',
                style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'انقر على القسم للإدارة',
                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ScreenUtil().screenWidth > 600 ? 4 : 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 14.w,
            mainAxisSpacing: 14.h,
          ),
          itemCount: categories.length,
          itemBuilder: (ctx, idx) {
            final cat = categories[idx];
            final catProductCount = products.where((p) => p.categoryId == cat.id).length;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _showForm = false;
                });
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: cat.gradientColors),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(cat.icon, color: Colors.white, size: 22.sp),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '$catProductCount منتج',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.title,
                          style: AppStyles.titleSmall.copyWith(fontSize: 14.sp, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              isAdmin ? 'إضافة/تعديل المنتجات' : 'استعراض المنتجات',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_left_rounded, color: AppColors.primaryAccent, size: 18.sp),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDetailPage(List<ProductModel> products, String baseUrl, bool isAdmin, bool isCustomer, ProductProvider productProvider) {
    final catId = _selectedCategory!.id;
    final catProducts = products.where((p) => p.categoryId == catId || (catId == 'wedding' && (p.categoryId == null || p.categoryId == ''))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Header Badge
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _selectedCategory!.gradientColors),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: AppStyles.cardShadow,
          ),
          child: Row(
            children: [
              Icon(_selectedCategory!.icon, color: Colors.white, size: 28.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قسم ${_selectedCategory!.title}',
                      style: AppStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'إجمالي المنتجات في هذا القسم: ${catProducts.length}',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Add / Edit Product Form
        if (isAdmin && _showForm) ...[
          _buildAddEditProductForm(productProvider),
          SizedBox(height: 20.h),
        ],

        // Products List inside Category
        if (catProducts.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.borderLight),
              borderRadius: AppStyles.cardRadius,
            ),
            child: Column(
              children: [
                Icon(Icons.style_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                SizedBox(height: 12.h),
                Text('لا توجد منتجات في قسم "${_selectedCategory!.title}" حالياً', style: AppStyles.bodyMuted),
                if (isAdmin) ...[
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showForm = true;
                      });
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text('إضافة منتج في ${_selectedCategory!.title}', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryAccent),
                  ),
                ],
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: catProducts.length,
            itemBuilder: (context, index) {
              final p = catProducts[index];
              final fullImageUrl = p.getFullImageUrl(baseUrl);

              return Container(
                margin: EdgeInsets.only(bottom: 18.h),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product image box
                    ProductImageWidget(
                      imageUrl: p.imageUrl,
                      baseUrl: baseUrl,
                      height: 180.h,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                    // Product info
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: AppStyles.titleMedium.copyWith(fontSize: 16.sp)),
                                    SizedBox(height: 4.h),
                                    Text(
                                      p.description.isEmpty ? 'بدون وصف' : p.description,
                                      style: AppStyles.bodyMuted,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '${p.price.toStringAsFixed(2)} ج.م',
                                  style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 12.sp),
                                ),
                              )
                            ],
                          ),
                          
                          const Divider(color: AppColors.borderLight, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isCustomer)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    PaymentMethodsModal.show(
                                      context,
                                      productName: p.name,
                                      productPrice: p.price,
                                      onConfirmOrder: (methodTitle, senderInfo, [proofFile]) {
                                        _showSnackbar('✓ تم استلام طلبك لـ "${p.name}" عبر $methodTitle بنجاح!', AppColors.successStart);
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 16),
                                  label: Text('طلب ودفع (كاش/انستاباي)', style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 12.sp)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryAccent,
                                    elevation: 2,
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  ),
                                ),
                              if (isAdmin) ...[
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _startEdit(p),
                                        icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                                        label: const Text('تعديل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryAccent,
                                          elevation: 1,
                                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      ElevatedButton.icon(
                                        onPressed: () => _deleteProduct(p.id),
                                        icon: const Icon(Icons.delete_forever, color: Colors.white, size: 16),
                                        label: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.dangerStart,
                                          elevation: 1,
                                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
      ],
    );
  }

  Widget _buildAddEditProductForm(ProductProvider productProvider) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4), width: 1.5),
        borderRadius: AppStyles.cardRadius,
        boxShadow: AppStyles.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    _editingProductId != null ? Icons.edit_note : Icons.add_business_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingProductId != null ? 'تعديل المنتج' : 'إضافة منتج جديد في قسم ${_selectedCategory!.title}',
                        style: AppStyles.titleSmall,
                      ),
                      Text(
                        'سيتم ربط هذا المنتج تلقائياً بقسم ${_selectedCategory!.title}',
                        style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp, color: AppColors.primaryAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight, height: 24),
            
            // Automatic Category Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(_selectedCategory!.icon, color: AppColors.primaryAccent, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text('القسم الحالي المربوط بالمنتج: ', style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
                  Text(
                    _selectedCategory!.title,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            Text('اسم المنتج', style: AppStyles.labelBold),
            SizedBox(height: 6.h),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(hintText: 'اسم المنتج'),
            ),
            SizedBox(height: 14.h),
            Text('الوصف', style: AppStyles.labelBold),
            SizedBox(height: 6.h),
            TextField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textMain),
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'تفاصيل مواصفات المنتج...'),
            ),
            SizedBox(height: 14.h),
            Text('السعر (ج.م)', style: AppStyles.labelBold),
            SizedBox(height: 6.h),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(hintText: '0.00'),
            ),
            SizedBox(height: 14.h),
            Text('صورة المنتج', style: AppStyles.labelBold),
            SizedBox(height: 6.h),
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  border: Border.all(color: AppColors.borderDark),
                  borderRadius: AppStyles.inputRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: AppColors.textMuted),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _selectedImage != null
                            ? _selectedImage!.path.split(Platform.pathSeparator).last
                            : 'اختر صورة للمنتج (اختياري)',
                        style: AppStyles.bodyDefault.copyWith(
                          color: _selectedImage != null ? Colors.white : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: productProvider.isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.buttonRadius),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: AppStyles.buttonRadius,
                  boxShadow: AppStyles.buttonShadow,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  alignment: Alignment.center,
                  child: productProvider.isLoading
                      ? SizedBox(
                          height: 18.w,
                          width: 18.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _editingProductId != null ? 'تحديث المنتج' : 'حفظ المنتج في قسم ${_selectedCategory!.title}',
                          style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 14.sp),
                        ),
                ),
              ),
            ),
            if (_editingProductId != null) ...[
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: _resetForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(color: Colors.white.withOpacity(0.18)),
                  shape: RoundedRectangleBorder(borderRadius: AppStyles.buttonRadius),
                ),
                child: Text('إلغاء التعديل', style: AppStyles.labelBold.copyWith(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
