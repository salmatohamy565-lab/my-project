import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_logo_bar.dart';

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

    final productProvider = context.read<ProductProvider>();
    bool success;

    if (_editingProductId != null) {
      success = await productProvider.editProduct(
        _editingProductId!,
        name,
        desc,
        price,
        _selectedImage,
      );
    } else {
      success = await productProvider.addProduct(
        name,
        desc,
        price,
        _selectedImage,
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

  void _startEdit(dynamic product) {
    setState(() {
      _editingProductId = product.id;
      _nameController.text = product.name;
      _descController.text = product.description;
      _priceController.text = product.price.toStringAsFixed(2);
      _selectedImage = null;
      _showForm = true;
    });
    // Scroll to form (since it is at the bottom, we can open and scroll)
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
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('منتجاتي', style: AppStyles.titleLarge),
                                Text(
                                  'عرض المنتجات وأسعارها التي تقدمها في الدعاية والإعلان',
                                  style: AppStyles.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          if (isAdmin)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showForm = !_showForm;
                                  if (!_showForm) _resetForm();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryAccent,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                              ),
                              child: Text(
                                _showForm ? 'إلغاء' : 'إضافة منتج جديد',
                                style: AppStyles.labelBold.copyWith(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Brand Hero card matching CSS .brand-hero - light, premium version
                      Container(
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
                                    width: 50.w,
                                    height: 50.w,
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
                                        'القائمة الاحترافية لمنتجات التصميم والإعلان الخاصة بك مع عرض الأسعار الواضح.',
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
                      ),
                      SizedBox(height: 24.h),

                      // Admin Save/Edit form card
                      if (isAdmin && _showForm) ...[
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.borderLight),
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
                                        _editingProductId != null ? Icons.edit_note : Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _editingProductId != null ? 'تعديل المنتج' : 'إضافة منتج جديد',
                                          style: AppStyles.titleSmall,
                                        ),
                                        Text(
                                          _editingProductId != null ? 'حدّث بيانات المنتج أو استبدل صورته' : 'يمكنك إضافة منتج جديد وسعره هنا',
                                          style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(color: AppColors.borderLight, height: 24),
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
                                              _editingProductId != null ? 'تحديث المنتج' : 'حفظ المنتج',
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
                        ),
                        SizedBox(height: 24.h),
                      ],

                      // Products section matching CSS grid
                      if (productProvider.isLoading && products.isEmpty)
                        const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                      else if (products.isEmpty)
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
                              Text('لا توجد منتجات حالياً', style: AppStyles.bodyMuted),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];
                            final fullImageUrl = p.getFullImageUrl(authProvider.baseUrl);

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
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                                                                    child: Container(
                                      height: 180.h,
                                      color: AppColors.bgMiddle,
                                      alignment: Alignment.center,
                                      child: fullImageUrl != null
                                          ? Image.network(
                                              fullImageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder: (context, error, stackTrace) => const Icon(
                                                Icons.broken_image_outlined,
                                                color: AppColors.textMuted,
                                                size: 40,
                                              ),
                                            )
                                          : Icon(Icons.image_outlined, color: AppColors.textMuted.withOpacity(0.6), size: 48),
                                    ),
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
                                        
                                        // Admin actions row
                                        if (isAdmin) ...[
                                          const Divider(color: AppColors.borderLight, height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _startEdit(p),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryAccent.withOpacity(0.14),
                                                  elevation: 0,
                                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                ),
                                                child: const Text('تعديل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                              SizedBox(width: 10.w),
                                              ElevatedButton(
                                                onPressed: () => _deleteProduct(p.id),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.dangerStart.withOpacity(0.14),
                                                  elevation: 0,
                                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                ),
                                                child: const Text('حذف', style: TextStyle(color: AppColors.dangerStart, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          )
                                        ],
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
}
