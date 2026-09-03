import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/product_image_widget.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // New Offer Form Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _offerPriceController = TextEditingController();
  final _origPriceController = TextEditingController();
  final _discountBadgeController = TextEditingController();
  final _offerDetailsController = TextEditingController();

  CategoryModel? _selectedCategory;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _offerPriceController.dispose();
    _origPriceController.dispose();
    _discountBadgeController.dispose();
    _offerDetailsController.dispose();
    super.dispose();
  }

  void _resetNewOfferForm() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedCategory = null;
      _nameController.clear();
      _descController.clear();
      _offerPriceController.clear();
      _origPriceController.clear();
      _discountBadgeController.clear();
      _offerDetailsController.clear();
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.single;
      setState(() {
        _selectedImageBytes = picked.bytes;
        _selectedImageName = picked.name;
        if (picked.path != null && !kIsWeb) {
          _selectedImage = File(picked.path!);
        } else {
          _selectedImage = null;
        }
      });
    }
  }

  Future<void> _saveNewOfferProduct() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final offerPriceStr = _offerPriceController.text.trim();
    final origPriceStr = _origPriceController.text.trim();
    final discount = _discountBadgeController.text.trim();
    final details = _offerDetailsController.text.trim();

    if (name.isEmpty || offerPriceStr.isEmpty) {
      _showSnackbar('يرجى كتابة اسم المنتج وسعر العرض على الأقل', Colors.red);
      return;
    }

    final offerPrice = double.tryParse(offerPriceStr);
    if (offerPrice == null) {
      _showSnackbar('سعر العرض يجب أن يكون رقماً صحيحاً', Colors.red);
      return;
    }

    final double? origPrice = origPriceStr.isNotEmpty ? double.tryParse(origPriceStr) : null;

    setState(() => _isSaving = true);

    final success = await context.read<ProductProvider>().addProduct(
      name,
      desc,
      offerPrice,
      _selectedImage,
      imageBytes: _selectedImageBytes,
      imageName: _selectedImageName,
      categoryId: _selectedCategory?.id,
      isOffer: true,
      originalPrice: origPrice ?? (offerPrice * 1.25),
      offerDiscount: discount.isNotEmpty ? discount : 'عرض خاص 🔥',
      offerDetails: details,
    );

    setState(() => _isSaving = false);

    if (success) {
      _resetNewOfferForm();
      _showSnackbar('تمت إضافة المنتج إلى قسم العروض بنجاح 🎉', AppColors.successStart);
      _tabController.animateTo(0);
    } else {
      final err = context.read<ProductProvider>().errorMessage ?? 'فشل إضافة العرض';
      _showSnackbar(err, Colors.red);
    }
  }

  Future<void> _showEditOfferDialog(ProductModel product) async {
    final editOfferPriceController = TextEditingController(text: product.price.toStringAsFixed(0));
    final editOrigPriceController = TextEditingController(text: product.originalPrice != null ? product.originalPrice!.toStringAsFixed(0) : '');
    final editDiscountController = TextEditingController(text: product.offerDiscount ?? '');
    final editDetailsController = TextEditingController(text: product.offerDetails ?? product.description);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تعديل تفاصيل العرض 🏷️', style: AppStyles.labelBold.copyWith(fontSize: 15.sp)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(product.name, style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                const Divider(color: AppColors.borderLight, height: 20),

                _buildTextField('سعر العرض (ج.م) *', editOfferPriceController, isNumber: true),
                SizedBox(height: 10.h),
                _buildTextField('السعر الأصلي قبل الخصم (ج.م)', editOrigPriceController, isNumber: true),
                SizedBox(height: 10.h),
                _buildTextField('شارة الخصم (مثال: 25% OFF أو وفر 50 ج.م)', editDiscountController),
                SizedBox(height: 10.h),
                _buildTextField('تفاصيل ومواصفات العرض', editDetailsController, maxLines: 3),
                SizedBox(height: 16.h),

                ElevatedButton(
                  onPressed: () async {
                    final op = double.tryParse(editOfferPriceController.text.trim());
                    if (op == null) {
                      _showSnackbar('سعر العرض غير صالح', Colors.red);
                      return;
                    }
                    final double? origP = double.tryParse(editOrigPriceController.text.trim());

                    Navigator.of(ctx).pop();
                    final success = await context.read<ProductProvider>().toggleProductOffer(
                      product.id,
                      true,
                      offerPrice: op,
                      originalPrice: origP,
                      offerDiscount: editDiscountController.text.trim(),
                      offerDetails: editDetailsController.text.trim(),
                    );
                    if (success) {
                      _showSnackbar('تم تحديث تفاصيل العرض بنجاح ✓', AppColors.successStart);
                    } else {
                      _showSnackbar('فشل تحديث العرض', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPromoteToOfferDialog(ProductModel product) async {
    final offerPriceController = TextEditingController(text: product.price > 0 ? (product.price * 0.85).toStringAsFixed(0) : '100');
    final origPriceController = TextEditingController(text: product.price > 0 ? product.price.toStringAsFixed(0) : '150');
    final discountController = TextEditingController(text: 'خصم 15% 🔥');
    final detailsController = TextEditingController(text: product.description);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تحويل المنتج إلى عرض 🎁', style: AppStyles.labelBold.copyWith(fontSize: 15.sp)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(product.name, style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                const Divider(color: AppColors.borderLight, height: 20),

                _buildTextField('سعر العرض المخفض (ج.م) *', offerPriceController, isNumber: true),
                SizedBox(height: 10.h),
                _buildTextField('السعر الأصلي قبل الخصم (ج.م)', origPriceController, isNumber: true),
                SizedBox(height: 10.h),
                _buildTextField('نص شارة الخصم (مثال: 20% OFF)', discountController),
                SizedBox(height: 10.h),
                _buildTextField('تفاصيل العرض والمواصفات', detailsController, maxLines: 3),
                SizedBox(height: 16.h),

                ElevatedButton(
                  onPressed: () async {
                    final op = double.tryParse(offerPriceController.text.trim());
                    if (op == null) {
                      _showSnackbar('يرجى إدخال سعر عرض صحيح', Colors.red);
                      return;
                    }
                    final double? origP = double.tryParse(origPriceController.text.trim());

                    Navigator.of(ctx).pop();
                    final success = await context.read<ProductProvider>().toggleProductOffer(
                      product.id,
                      true,
                      offerPrice: op,
                      originalPrice: origP ?? product.price,
                      offerDiscount: discountController.text.trim(),
                      offerDetails: detailsController.text.trim(),
                    );
                    if (success) {
                      _showSnackbar('تمت إضافة المنتج لقسم العروض بنجاح 🎉', AppColors.successStart);
                      _tabController.animateTo(0);
                    } else {
                      _showSnackbar('فشل تحويل المنتج لعرض', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text('تأكيد وإضافة للعروض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeFromOffers(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('إلغاء من العروض', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في إزالة "${product.name}" من قسم العروض؟ (سيبقى المنتج في المتجر كمنتج عادي)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text('إزالة من العروض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<ProductProvider>().toggleProductOffer(
        product.id,
        false,
      );
      if (success) {
        _showSnackbar('تمت إزالة المنتج من قسم العروض', AppColors.successStart);
      } else {
        _showSnackbar('فشل التحديث', Colors.red);
      }
    }
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.bodyMuted.copyWith(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColors.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColors.primaryAccent)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final allProducts = productProvider.products;
    final activeOffers = allProducts.where((p) => p.isOffer).toList();
    final nonOfferProducts = allProducts.where((p) => !p.isOffer).toList();

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            const AppLogoBar(username: 'إدارة قسم العروض'),

            // Title & Back row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إدارة قسم العروض والخصومات 🏷️', style: AppStyles.titleMedium.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        Text('أضف وتحكم في المنتجات الحصرية المعروضة في قسم العروض', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tabs Header
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryAccent,
                labelColor: AppColors.primaryAccent,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                tabs: [
                  Tab(text: 'العروض النشطة (${activeOffers.length})'),
                  const Tab(text: 'إضافة عرض جديد ➕'),
                  Tab(text: 'تحويل منتج لعرض (${nonOfferProducts.length})'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Active Offers
                  _buildActiveOffersTab(activeOffers, productProvider),

                  // Tab 2: Add New Offer Form
                  _buildAddNewOfferTab(productProvider),

                  // Tab 3: Promote existing products
                  _buildPromoteExistingTab(nonOfferProducts, productProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOffersTab(List<ProductModel> offers, ProductProvider productProvider) {
    if (offers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined, size: 64.r, color: AppColors.textMuted.withOpacity(0.5)),
              SizedBox(height: 14.h),
              Text(
                'لا توجد عروض نشطة حالياً',
                style: AppStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6.h),
              Text(
                'قسم العروض فارغ في الشاشة الرئيسية. يمكنك إضافة عرض جديد الآن أو تحويل أي منتج موجود إلى عرض.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp),
              ),
              SizedBox(height: 18.h),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('إضافة أول عرض الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => productProvider.fetchProducts(),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: offers.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final product = offers[index];
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3), width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8.r, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: SizedBox(
                        width: 72.w,
                        height: 72.h,
                        child: ProductImageWidget(
                          imageUrl: product.imageUrl,
                          baseUrl: _apiService.baseUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Title, Badges & Prices
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  product.offerDiscount ?? 'عرض خاص 🔥',
                                  style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(product.name, style: AppStyles.labelBold.copyWith(fontSize: 13.5.sp)),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Text(
                                '${product.price.toStringAsFixed(0)} ج.م',
                                style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 14.sp),
                              ),
                              if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                                SizedBox(width: 8.w),
                                Text(
                                  '${product.originalPrice!.toStringAsFixed(0)} ج.م',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11.sp,
                                    decoration: TextDecoration.lineThrough,
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

                // Offer details
                if (product.offerDetails != null && product.offerDetails!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'المواصفات والتفاصيل: ${product.offerDetails}',
                      style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                    ),
                  ),
                ],

                const Divider(color: AppColors.borderLight, height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditOfferDialog(product),
                        icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primaryAccent),
                        label: const Text('تعديل التفاصيل', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _removeFromOffers(product),
                        icon: Icon(Icons.remove_circle_outline, size: 18, color: Colors.orange.shade800),
                        label: Text('إزالة من العروض', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange.shade800),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddNewOfferTab(ProductProvider productProvider) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('بيانات المنتج والعرض الجديد 🏷️', style: AppStyles.labelBold.copyWith(fontSize: 14.sp)),
            const Divider(color: AppColors.borderLight, height: 16),

            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120.h,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : (_selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 36.r, color: AppColors.primaryAccent),
                          SizedBox(height: 6.h),
                          Text('انقر هنا لاختيار صورة للمنتج', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 12.h),

            _buildTextField('اسم المنتج *', _nameController),
            SizedBox(height: 10.h),

            Row(
              children: [
                Expanded(child: _buildTextField('سعر العرض (ج.م) *', _offerPriceController, isNumber: true)),
                SizedBox(width: 10.w),
                Expanded(child: _buildTextField('السعر قبل الخصم (ج.م)', _origPriceController, isNumber: true)),
              ],
            ),
            SizedBox(height: 10.h),

            _buildTextField('شارة الخصم (مثال: خصم 25% 🔥)', _discountBadgeController),
            SizedBox(height: 10.h),

            // Category Selector
            Text('القسم الرئيسي للطلب', style: AppStyles.bodyMuted.copyWith(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CategoryModel?>(
                  isExpanded: true,
                  value: _selectedCategory != null && productProvider.categories.any((c) => c.id == _selectedCategory!.id)
                      ? productProvider.categories.firstWhere((c) => c.id == _selectedCategory!.id)
                      : null,
                  hint: Text('اختر القسم التابع له (اختياري)', style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
                  items: [
                    const DropdownMenuItem<CategoryModel?>(
                      value: null,
                      child: Text('بدون قسم رئيسي (افتراضي)', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    ...productProvider.categories.map((cat) {
                      return DropdownMenuItem<CategoryModel?>(
                        value: cat,
                        child: Text(cat.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }),
                  ],
                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            _buildTextField('مواصفات وتفاصيل العرض والمنتج بالكامل', _offerDetailsController, maxLines: 3),
            SizedBox(height: 16.h),

            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveNewOfferProduct,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ ونشر العرض فوراً 🚀', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoteExistingTab(List<ProductModel> products, ProductProvider productProvider) {
    if (products.isEmpty) {
      return const Center(child: Text('جميع المنتجات مضافة كعروض بالفعل أو لا توجد منتجات.'));
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: products.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final prod = products[index];
        return Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  width: 50.w,
                  height: 50.h,
                  child: ProductImageWidget(
                    imageUrl: prod.imageUrl,
                    baseUrl: _apiService.baseUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prod.name, style: AppStyles.labelBold.copyWith(fontSize: 13.sp)),
                    Text('السعر الحالي: ${prod.price.toStringAsFixed(0)} ج.م', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showPromoteToOfferDialog(prod),
                icon: const Icon(Icons.local_offer, size: 16, color: Colors.white),
                label: Text('جعله عرضاً', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
