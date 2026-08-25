import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../utils/web_file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/radial_background.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/app_logo_bar.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../widgets/payment_methods_modal.dart';
import '../widgets/product_image_widget.dart';
import 'login_screen.dart';
import 'admin/archived_tasks_screen.dart';
import 'admin/archived_files_screen.dart';
import '../utils/copy_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoadingOrders = false;
  List<dynamic> _rawOrders = [];
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _fetchCustomerOrders();
    _initOrdersRealtimeStream();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _initOrdersRealtimeStream() {
    try {
      _ordersSubscription = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((List<Map<String, dynamic>> payload) {
        if (!mounted) return;
        _updateOrdersFromList(payload);
      }, onError: (err) {
        _fetchCustomerOrders();
      });
    } catch (_) {}
  }

  Future<void> _updateOrdersFromList(List<dynamic> data) async {
    if (!mounted) return;
    List<dynamic> merged = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedJson = prefs.getString('user_saved_orders');
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> localOrders = jsonDecode(savedJson);
        merged.addAll(localOrders);
      }
    } catch (_) {}

    try {
      final providerOrders = context.read<OrderProvider>().orders;
      for (final po in providerOrders) {
        final pJson = po.toJson();
        final idStr = po.id.toString();
        if (!merged.any((o) => (o['id'] ?? '').toString() == idStr)) {
          merged.insert(0, pJson);
        }
      }
    } catch (_) {}

    for (final item in data) {
      final idStr = (item['id'] ?? '').toString();
      if (idStr.isEmpty) continue;
      final existingIdx = merged.indexWhere((o) => (o['id'] ?? '').toString() == idStr);
      if (existingIdx >= 0) {
        final existing = Map<String, dynamic>.from(merged[existingIdx]);
        existing.addAll(Map<String, dynamic>.from(item));
        merged[existingIdx] = existing;
      } else {
        merged.insert(0, item);
      }
    }

    final user = context.read<AuthProvider>().currentUser;
    final isStaff = user != null && (user.isAdmin || user.isEmployee);
    if (!isStaff) {
      merged.retainWhere((o) => _isOrderBelongingToUser(o, user));
    }

    if (!mounted) return;
    setState(() {
      _rawOrders = merged;
      _isLoadingOrders = false;
    });
  }

  Future<void> _fetchCustomerOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingOrders = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      final res = await _apiService.getOrders(
        userId: user?.id,
        userPhone: user?.phone,
        userName: user?.username ?? user?.name,
        isStaff: user != null && (user.isAdmin || user.isEmployee),
      );
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> data = res.data ?? [];
        _updateOrdersFromList(data);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  bool _isOrderBelongingToUser(dynamic o, UserModel? user) {
    if (user == null) return false;
    final uId = (user.id ?? 0).toString();
    final uPhone = (user.phone ?? '').trim();
    final uEmail = (user.email ?? '').trim().toLowerCase();
    final uName = (user.displayName ?? user.name ?? user.username ?? '').trim().toLowerCase();

    final oUserId = (o['user_id'] ?? o['userId'] ?? '').toString();
    final oPhone = (o['customer_phone'] ?? o['customerPhone'] ?? o['sender_info'] ?? '').toString().trim();
    final oName = (o['customer_name'] ?? o['customerName'] ?? '').toString().trim().toLowerCase();

    if (uId.isNotEmpty && uId != '0' && oUserId.isNotEmpty && oUserId != '0' && oUserId == uId) {
      return true;
    }
    if (uPhone.length >= 7 && oPhone.length >= 7 && (oPhone.contains(uPhone) || uPhone.contains(oPhone))) {
      return true;
    }
    if (uName.isNotEmpty && oName.isNotEmpty && (oName.contains(uName) || uName.contains(oName))) {
      return true;
    }
    if (uEmail.isNotEmpty && oName.contains(uEmail.split('@').first)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final currentUser = authProvider.currentUser;
    final bool isAdmin = currentUser?.isAdmin ?? false;
    final bool isStaff = currentUser != null && (currentUser.isAdmin || currentUser.isEmployee);

    final List<dynamic> combinedOrdersList = [];
    for (final po in orderProvider.orders) {
      combinedOrdersList.add(po.toJson());
    }
    for (final r in _rawOrders) {
      final idStr = (r['id'] ?? '').toString();
      if (idStr.isNotEmpty && !combinedOrdersList.any((o) => (o['id'] ?? '').toString() == idStr)) {
        combinedOrdersList.add(r);
      }
    }

    if (!isStaff) {
      combinedOrdersList.retainWhere((o) => _isOrderBelongingToUser(o, currentUser));
    }

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(
              username: currentUser?.displayName ?? 'مستخدم Bola',
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
                                child: Icon(Icons.person_rounded, size: 40.r, color: AppColors.primaryAccent),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentUser?.displayName ?? 'مستخدم Bola',
                                      style: AppStyles.titleMedium.copyWith(fontSize: 18.sp),
                                    ),
                                    if (currentUser?.email != null && currentUser!.email!.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(currentUser.email!, style: AppStyles.bodyMuted),
                                    ],
                                    if (currentUser?.phone != null && currentUser!.phone!.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(currentUser.phone!, style: AppStyles.bodyMuted),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // User Orders List Section ("أوردراتي")
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shopping_bag_outlined, color: AppColors.primaryAccent, size: 22.r),
                                  SizedBox(width: 8.w),
                                  Text(
                                    isStaff ? 'الطلبات الحالية (${combinedOrdersList.length})' : 'أوردراتي (${combinedOrdersList.length})',
                                    style: AppStyles.titleMedium.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          if (_isLoadingOrders && combinedOrdersList.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
                            )
                          else if (combinedOrdersList.isEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 36.r),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'لم تقم بإجراء أي أوردرات حتى الآن',
                                    style: AppStyles.bodyMuted.copyWith(fontSize: 13.sp),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: combinedOrdersList.length,
                              separatorBuilder: (_, __) => SizedBox(height: 10.h),
                              itemBuilder: (context, idx) {
                                final item = combinedOrdersList[idx];
                                final id = item['id'] ?? 0;
                                final status = (item['status'] ?? 'pending').toString().toLowerCase();
                                final total = item['total_price'] ?? item['total'] ?? 0;
                                final date = item['created_at'] != null ? item['created_at'].toString().split('T').first : '';
                                final itemsSummary = (item['items_summary'] ?? '').toString();

                                String statusLabel = 'قيد الموافقة';
                                Color statusColor = Colors.orange;

                                if (status == 'preparing' || status == 'in_progress' || status == 'processing' || status == 'approved') {
                                  statusLabel = 'جاري التجهيز';
                                  statusColor = Colors.blueAccent;
                                } else if (status == 'ready') {
                                  statusLabel = 'جاهز للتوصيل';
                                  statusColor = Colors.purpleAccent;
                                } else if (status == 'completed' || status == 'done' || status == 'delivered') {
                                  statusLabel = 'مكتمل';
                                  statusColor = AppColors.emeraldGreen;
                                } else if (status == 'rejected') {
                                  statusLabel = 'مرفوض';
                                  statusColor = AppColors.dangerStart;
                                }

                                return Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('أوردر #$id', style: AppStyles.labelBold.copyWith(fontSize: 13.sp)),
                                          Text('$total ج.م', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        itemsSummary.isNotEmpty ? itemsSummary : 'تفاصيل الأوردر',
                                        style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                      ),
                                      SizedBox(height: 6.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (date.isNotEmpty)
                                            Text(date, style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp)),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(color: statusColor, fontSize: 10.5.sp, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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
}
