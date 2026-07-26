import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/radial_background.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/app_logo_bar.dart';
import '../widgets/payment_methods_modal.dart';
import 'login_screen.dart';
import 'admin/archived_tasks_screen.dart';
import 'admin/archived_files_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _cancelledOrders = [];
  List<OrderModel> _cartOrders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final resPending = await _apiService.getOrders(status: 'pending');
      final resCancelled = await _apiService.getOrders(status: 'cancelled');
      final resCart = await _apiService.getOrders(status: 'cart');

      if (mounted) {
        setState(() {
          _pendingOrders = (resPending.data as List).map((e) => OrderModel.fromJson(e)).toList();
          _cancelledOrders = (resCancelled.data as List).map((e) => OrderModel.fromJson(e)).toList();
          _cartOrders = (resCart.data as List).map((e) => OrderModel.fromJson(e)).toList();
          _isLoadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    final nameCtrl = TextEditingController(text: user?.name ?? user?.username ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    File? selectedPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تعديل البيانات الشخصية',
                      style: AppStyles.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),

                    // Avatar Edit
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(type: FileType.image);
                          if (result != null && result.files.single.path != null) {
                            setModalState(() {
                              selectedPhoto = File(result.files.single.path!);
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 40.r,
                          backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                          backgroundImage: selectedPhoto != null
                              ? FileImage(selectedPhoto!) as ImageProvider
                              : (user?.photoUrl != null
                                  ? NetworkImage('${authProvider.baseUrl}${user!.photoUrl}') as ImageProvider
                                  : null),
                          child: (selectedPhoto == null && user?.photoUrl == null)
                              ? const Icon(Icons.camera_alt, color: AppColors.primaryAccent)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    TextField(
                      controller: nameCtrl,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    ),
                    SizedBox(height: 20.h),

                    ElevatedButton(
                      onPressed: () async {
                        final success = await authProvider.updateProfile(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          photo: selectedPhoto,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث البيانات بنجاح!'),
                              backgroundColor: AppColors.emeraldGreen,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('حفظ التعديلات', style: AppStyles.buttonText),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final bool isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(
              username: currentUser?.displayName ?? 'المستخدم',
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 36.r,
                                backgroundColor: AppColors.primaryAccent.withOpacity(0.08),
                                backgroundImage: (currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty)
                                    ? NetworkImage(currentUser.photoUrl!.startsWith('http')
                                        ? currentUser.photoUrl!
                                        : '${authProvider.baseUrl}${currentUser.photoUrl}') as ImageProvider
                                    : null,
                                child: (currentUser?.photoUrl == null || currentUser!.photoUrl!.isEmpty)
                                    ? Icon(Icons.person_rounded, size: 40.r, color: AppColors.primaryAccent)
                                    : null,
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentUser?.displayName ?? 'المستخدم',
                                      style: AppStyles.titleMedium.copyWith(fontSize: 18.sp),
                                    ),
                                    if (currentUser?.email != null && currentUser!.email!.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(currentUser.email!, style: AppStyles.bodyMuted),
                                    ],
                                    if (currentUser?.phone != null && currentUser!.phone!.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(currentUser.phone!, style: AppStyles.bodyMuted),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryAccent),
                                onPressed: () => _showEditProfileDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Loyalty Points & Rewards Card
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, _) {
                        final points = cartProvider.userLoyaltyPoints;
                        final equivalentDiscount = (points / 5).toDouble();

                        return Container(
                          padding: EdgeInsets.all(18.r),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF343A40), Color(0xFF0A0A0A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: AppStyles.cardRadius,
                            border: Border.all(color: AppColors.borderDark, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12.r,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.stars_rounded, color: Colors.white, size: 24.r),
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'نقاط المكافآت والخصم',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      'رصيدك الحالي',
                                      style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$points نقطة',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22.sp),
                                      ),
                                      Text(
                                        'تساوي خصم بقيمة ${equivalentDiscount.toStringAsFixed(0)} ج.م على مشترياتك',
                                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.sp),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🛍️ يمكنك استخدام نقاطك للحصول على خصم مباشر داخل السلة عند الشراء!'),
                                          backgroundColor: AppColors.primaryAccent,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primaryAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    ),
                                    child: const Text('تفاصيل النقاط', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Orders Header & Tabs
                    Text(
                      'طلباتك وسلة الشراء',
                      style: AppStyles.labelBold.copyWith(fontSize: 15.sp),
                    ),
                    SizedBox(height: 10.h),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryAccent,
                        unselectedLabelColor: AppColors.textMuted,
                        indicatorColor: AppColors.primaryAccent,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'الطلبات الحالية'),
                          Tab(text: 'الملغية'),
                          Tab(text: 'السلة'),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Orders List Views (Tab Bar View Container)
                    SizedBox(
                      height: 320.h,
                      child: _isLoadingOrders
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOrdersList(_pendingOrders, 'لا توجد طلبات حالية معلقة'),
                                _buildOrdersList(_cancelledOrders, 'لا توجد طلبات ملغية'),
                                _buildOrdersList(_cartOrders, 'سلة الشراء فارغة'),
                              ],
                            ),
                    ),
                    SizedBox(height: 20.h),

                    // Actions List
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.account_balance_wallet,
                            title: 'طرق الدفع والتحويل (كاش / انستاباي)',
                            onTap: () => PaymentMethodsModal.show(context),
                          ),
                          const Divider(color: AppColors.borderLight, height: 1),
                          if (isAdmin) ...[
                            _buildListTile(
                              icon: Icons.archive_outlined,
                              title: 'المهام المؤرشفة',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ArchivedTasksScreen()),
                              ),
                            ),
                            const Divider(color: AppColors.borderLight, height: 1),
                            _buildListTile(
                              icon: Icons.folder_open_outlined,
                              title: 'الملفات المؤرشفة',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ArchivedFilesScreen()),
                              ),
                            ),
                            const Divider(color: AppColors.borderLight, height: 1),
                          ],
                          _buildListTile(
                            icon: Icons.support_agent_rounded,
                            title: 'الدعم والمساعدة',
                            onTap: () => _showSupportDialog(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Logout Button
                    ElevatedButton(
                      onPressed: () async {
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerStart,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 8.w),
                          Text('تسجيل الخروج', style: AppStyles.labelBold.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentRoute: 'profile',
        isAdmin: isAdmin,
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 48.sp, color: AppColors.textMuted),
            SizedBox(height: 8.h),
            Text(emptyMsg, style: AppStyles.bodyMuted),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (ctx, idx) {
          final order = orders[idx];
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب #${order.id}', style: AppStyles.labelBold),
                    SizedBox(height: 4.h),
                    Text(
                      'المبلغ: ${order.totalPrice.toStringAsFixed(2)} جنيه',
                      style: AppStyles.bodyMuted.copyWith(color: AppColors.primaryAccent),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: AppStyles.labelBold.copyWith(
                      color: _getStatusColor(order.status),
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return AppColors.dangerStart;
      case 'cart':
        return AppColors.primaryAccent;
      default:
        return AppColors.emeraldGreen;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'cancelled':
        return 'ملغي';
      case 'cart':
        return 'في السلة';
      default:
        return status;
    }
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent),
      title: Text(
        title,
        style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('الدعم والمساعدة', textAlign: TextAlign.right, style: AppStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'للدعم والاستفسار يرجى التواصل مع الإدارة أو Bola Designs على الرقم التالي:',
              textAlign: TextAlign.right,
              style: AppStyles.bodyDefault,
            ),
            SizedBox(height: 16.h),
            Text(
              '01228569626',
              textAlign: TextAlign.center,
              style: AppStyles.titleLarge.copyWith(color: AppColors.primaryAccent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }
}
