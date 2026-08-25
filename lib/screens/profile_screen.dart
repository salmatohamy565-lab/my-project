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
  int _pendingCount = 0;
  int _preparingCount = 0;
  int _readyCount = 0;
  int _completedCount = 0;
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
        print('[SUPABASE REALTIME ORDERS STREAM ERROR] $err');
        _fetchCustomerOrders();
      });
    } catch (e) {
      print('[SUPABASE REALTIME STREAM INIT NOTICE] $e');
    }
  }

  Future<void> _updateOrdersFromList(List<dynamic> data) async {
    if (!mounted) return;

    List<dynamic> merged = List.from(data);

    final user = context.read<AuthProvider>().currentUser;
    final isStaff = user != null && (user.isAdmin || user.isEmployee);
    if (!isStaff) {
      merged.retainWhere((o) => _isOrderBelongingToUser(o, user));
    }

    // ALWAYS SORT FROM NEWEST TO OLDEST (من الأحدث للأقدم)
    merged.sort((a, b) {
      final idA = (a['id'] ?? 0) is int ? a['id'] as int : int.tryParse(a['id'].toString()) ?? 0;
      final idB = (b['id'] ?? 0) is int ? b['id'] as int : int.tryParse(b['id'].toString()) ?? 0;
      return idB.compareTo(idA);
    });

    if (!mounted) return;

    setState(() {
      _rawOrders = merged;
      _pendingCount = merged.where((o) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        return st == 'pending' || st == 'pending_approval';
      }).length;

      _preparingCount = merged.where((o) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        return st == 'preparing' || st == 'in_progress' || st == 'processing' || st == 'approved';
      }).length;

      _readyCount = merged.where((o) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        return st == 'ready' || st == 'delivering';
      }).length;

      _completedCount = merged.where((o) {
        final st = (o['status'] ?? '').toString().toLowerCase();
        return st == 'delivered' || st == 'completed' || st == 'done';
      }).length;

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
    final uPhone = (user.phone ?? '').trim().replaceAll(RegExp(r'\D'), '');
    final uName = (user.displayName ?? user.name ?? user.username ?? '').trim().toLowerCase();

    final oId = (o['id'] ?? '').toString();
    final oUserId = (o['user_id'] ?? o['userId'] ?? '').toString();
    final oPhone = (o['customer_phone'] ?? o['customerPhone'] ?? o['sender_info'] ?? '').toString().trim().replaceAll(RegExp(r'\D'), '');
    final oName = (o['customer_name'] ?? o['customerName'] ?? '').toString().trim().toLowerCase();

    // 1. Locally registered created order in this session
    final myOrderIds = context.read<OrderProvider>().myOrderIds;
    if (myOrderIds.contains(oId)) return true;

    // 2. User ID match
    if (uId.isNotEmpty && uId != '0' && oUserId.isNotEmpty && oUserId != '0' && oUserId == uId) {
      return true;
    }

    // 3. Phone match
    if (uPhone.length >= 8 && oPhone.length >= 8 && (oPhone == uPhone || oPhone.endsWith(uPhone) || uPhone.endsWith(oPhone))) {
      return true;
    }

    // 4. Name match
    if (uName.length >= 2 && oName.length >= 2 && (oName == uName || oName.contains(uName) || uName.contains(oName))) {
      return true;
    }

    return false;
  }

  void _showOrdersModal(BuildContext context, {String? filterStatus, String? filterTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        final user = context.read<AuthProvider>().currentUser;
        final isStaff = user != null && (user.isAdmin || user.isEmployee);

        final providerOrders = context.read<OrderProvider>().orders;
        final List<dynamic> combined = [];
        for (final po in providerOrders) {
          combined.add(po.toJson());
        }
        for (final r in _rawOrders) {
          final idStr = (r['id'] ?? '').toString();
          if (idStr.isNotEmpty && !combined.any((o) => (o['id'] ?? '').toString() == idStr)) {
            combined.add(r);
          }
        }

        if (!isStaff) {
          combined.retainWhere((o) => _isOrderBelongingToUser(o, user));
        }

        List<dynamic> filtered = combined;
        if (filterStatus != null) {
          filtered = combined.where((o) {
            final st = (o['status'] ?? '').toString().toLowerCase();
            if (filterStatus == 'pending') return st == 'pending' || st == 'pending_approval';
            if (filterStatus == 'preparing') return st == 'preparing' || st == 'in_progress' || st == 'processing' || st == 'approved';
            if (filterStatus == 'ready') return st == 'ready' || st == 'delivering';
            if (filterStatus == 'completed') return st == 'completed' || st == 'done' || st == 'delivered';
            return true;
          }).toList();
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    filterTitle ?? 'سجل طلباتي وتتبع الحالة',
                    style: AppStyles.titleMedium.copyWith(fontSize: 18.sp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderLight),
              SizedBox(height: 8.h),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 48.sp, color: AppColors.textMuted),
                            SizedBox(height: 10.h),
                            Text('لا توجد طلبات في هذه الحالة حالياً', style: AppStyles.bodyMuted),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => SizedBox(height: 14.h),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final id = item['id'] ?? 0;
                          final status = (item['status'] ?? 'pending').toString().toLowerCase();
                          final total = item['total_price'] ?? item['total'] ?? 0;
                          final date = item['created_at'] != null
                              ? item['created_at'].toString().split('T').first
                              : '';

                          String statusLabel = 'بانتظار موافقة الأدمن وإثبات الدفع';
                          Color statusColor = Colors.orange;
                          IconData statusIcon = Icons.hourglass_top_rounded;
                          int currentStep = 1;

                          if (status == 'preparing' || status == 'in_progress' || status == 'processing' || status == 'approved') {
                            statusLabel = '🎉 تمت الموافقة! جاري تجهيز الطلب الآن';
                            statusColor = Colors.blueAccent;
                            statusIcon = Icons.precision_manufacturing_rounded;
                            currentStep = 2;
                          } else if (status == 'ready') {
                            statusLabel = '🚚 الطلب جاهز وفي طريقه إليك';
                            statusColor = Colors.purpleAccent;
                            statusIcon = Icons.local_shipping_rounded;
                            currentStep = 3;
                          } else if (status == 'completed' || status == 'done' || status == 'delivered') {
                            statusLabel = '✅ تم تسليم الطلب بنجاح';
                            statusColor = AppColors.emeraldGreen;
                            statusIcon = Icons.task_alt_rounded;
                            currentStep = 4;
                          } else if (status == 'rejected') {
                            statusLabel = '❌ تم رفض إثبات الدفع للطلب';
                            statusColor = AppColors.dangerStart;
                            statusIcon = Icons.error_outline_rounded;
                            currentStep = 0;
                          }

                          final itemsSummary = (item['items_summary'] ?? '').toString();
                          final rejectionReason = (item['rejection_reason'] ?? '').toString();
                          final proofUrl = item['payment_proof_url'] ?? item['payment_proof_filename'];

                          final orderModel = OrderModel.fromJson(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item));
                          final orderProducts = orderModel.products;

                          return Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(color: statusColor.withOpacity(0.4), width: 1.2),
                              boxShadow: AppStyles.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Order ID & Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18.r,
                                          backgroundColor: statusColor.withOpacity(0.15),
                                          child: Icon(statusIcon, color: statusColor, size: 18.r),
                                        ),
                                        SizedBox(width: 10.w),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('طلب رقم #$id', style: AppStyles.labelBold.copyWith(fontSize: 16.sp)),
                                            if (date.isNotEmpty)
                                              Text(date, style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text('$total ج.م', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent, fontSize: 16.sp)),
                                  ],
                                ),
                                SizedBox(height: 10.h),

                                // Status Banner
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(height: 12.h),

                                // Step Indicator (Timeline Bar) if not rejected
                                if (status != 'rejected') ...[
                                  Row(
                                    children: [
                                      _buildStepDot(1, 'تم الإرسال', currentStep >= 1, Colors.orange),
                                      _buildStepLine(currentStep >= 2, Colors.blueAccent),
                                      _buildStepDot(2, 'الموافقة والتجهيز', currentStep >= 2, Colors.blueAccent),
                                      _buildStepLine(currentStep >= 3, Colors.purpleAccent),
                                      _buildStepDot(3, 'جاهز للتوصيل', currentStep >= 3, Colors.purpleAccent),
                                      _buildStepLine(currentStep >= 4, AppColors.emeraldGreen),
                                      _buildStepDot(4, 'تم التسليم', currentStep >= 4, AppColors.emeraldGreen),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                ],

                                if (itemsSummary.isNotEmpty) ...[
                                  Text('المنتجات: $itemsSummary', style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp)),
                                  SizedBox(height: 6.h),
                                ],

                                if (orderProducts.isNotEmpty) ...[
                                  Text('معاينة المنتجات (انقر للمعاينة والاطلاع على الصورة 🔍):', style: AppStyles.labelBold.copyWith(fontSize: 11.sp)),
                                  SizedBox(height: 6.h),
                                  SizedBox(
                                    height: 60.h,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: orderProducts.length,
                                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                                      itemBuilder: (context, pIdx) {
                                        final prod = orderProducts[pIdx];
                                        return InkWell(
                                          onTap: () => _showCustomerProductDetail(context, prod),
                                          borderRadius: BorderRadius.circular(10.r),
                                          child: Container(
                                            width: 150.w,
                                            padding: EdgeInsets.all(6.r),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardBg,
                                              borderRadius: BorderRadius.circular(10.r),
                                              border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8.r),
                                                  child: SizedBox(
                                                    width: 40.w,
                                                    height: 40.h,
                                                    child: ProductImageWidget(
                                                      imageUrl: prod.imageUrl,
                                                      baseUrl: ApiService().baseUrl,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 6.w),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        prod.name.isNotEmpty ? prod.name : 'منتج',
                                                        style: TextStyle(color: AppColors.textMain, fontSize: 10.5.sp, fontWeight: FontWeight.bold),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        '${prod.price.toStringAsFixed(0)} ج.م',
                                                        style: TextStyle(color: AppColors.primaryAccent, fontSize: 10.sp),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                ],

                                 // Payment Receipt Image Display
                                 if (proofUrl != null && proofUrl.toString().isNotEmpty) ...[
                                   SizedBox(height: 8.h),
                                   Row(
                                     children: [
                                       Icon(Icons.receipt_long_rounded, color: AppColors.primaryAccent, size: 18.r),
                                       SizedBox(width: 6.w),
                                       Text('صورة إيصال الدفع 🧾:', style: AppStyles.labelBold.copyWith(fontSize: 12.sp, color: AppColors.primaryAccent)),
                                     ],
                                   ),
                                   SizedBox(height: 6.h),
                                   GestureDetector(
                                     onTap: () => _showImageZoom(context, proofUrl.toString(), id),
                                     child: ClipRRect(
                                       borderRadius: BorderRadius.circular(12.r),
                                       child: Container(
                                         height: 140.h,
                                         width: double.infinity,
                                         color: Colors.black,
                                         child: Stack(
                                           alignment: Alignment.center,
                                           children: [
                                             _buildReceiptImageWidget(proofUrl.toString(), fit: BoxFit.contain),
                                             Positioned(
                                               bottom: 8.h,
                                               child: Container(
                                                 padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                                 decoration: BoxDecoration(
                                                   color: Colors.black.withOpacity(0.75),
                                                   borderRadius: BorderRadius.circular(8.r),
                                                 ),
                                                 child: Row(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                                     SizedBox(width: 4.w),
                                                     Text('معاينة وتكبير صورة الإيصال 🔍', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                                                   ],
                                                 ),
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),
                                   SizedBox(height: 8.h),
                                 ],

                                // Rejection Notice Box
                                if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(10.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerStart.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(color: AppColors.dangerStart.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.cancel, color: AppColors.dangerStart, size: 18),
                                            SizedBox(width: 6.w),
                                            Text('سبب رفض إثبات الدفع:', style: TextStyle(color: AppColors.dangerStart, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(rejectionReason, style: TextStyle(color: AppColors.dangerStart, fontSize: 12.sp)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptImageWidget(String url, {BoxFit fit = BoxFit.contain}) {
    if (url.trim().isEmpty) {
      return const Center(child: Text('لا توجد صورة إيصال', style: TextStyle(color: Colors.white)));
    }
    final cleanUrl = url.trim();
    if (cleanUrl.contains('data:image') || (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://') && cleanUrl.length > 50)) {
      try {
        final commaIdx = cleanUrl.indexOf(',');
        final rawBase64 = commaIdx != -1 ? cleanUrl.substring(commaIdx + 1) : cleanUrl;
        final cleanBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: fit,
          errorBuilder: (_, err, ___) {
            print('[PROFILE BASE64 IMAGE DECODE ERROR] $err');
            return const Center(child: Text('تعذر تحميل صورة الإيصال', style: TextStyle(color: Colors.white)));
          },
        );
      } catch (e) {
        print('[PROFILE BASE64 PARSE ERROR] $e');
      }
    }
    return Image.network(
      cleanUrl,
      width: double.infinity,
      fit: fit,
      errorBuilder: (_, err, ___) {
        print('[PROFILE NETWORK IMAGE LOAD ERROR] $err for $cleanUrl');
        return const Center(child: Text('تعذر تحميل صورة الإيصال', style: TextStyle(color: Colors.white)));
      },
    );
  }

  void _showImageZoom(BuildContext context, String imageUrl, dynamic orderId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(12.w),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('إيصال الدفع - طلب #$orderId', style: AppStyles.labelBold),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  color: Colors.black,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildReceiptImageWidget(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerProductDetail(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.w),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name.isNotEmpty ? product.name : 'تفاصيل المنتج',
                        style: AppStyles.titleMedium.copyWith(fontSize: 16.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderLight),
                SizedBox(height: 10.h),
                if (product.imageUrl != null && product.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      height: 200.h,
                      color: Colors.black12,
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 48),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
                Text('تفاصيل المنتج:', style: AppStyles.labelBold.copyWith(fontSize: 13.sp)),
                SizedBox(height: 4.h),
                Text(
                  product.description.isNotEmpty ? product.description : 'منتج أصلي مميز من Bola Designs',
                  style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('السعر:', style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp)),
                    Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label, bool isActive, Color color) {
    return Expanded(
      flex: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9.r,
            backgroundColor: isActive ? color : Colors.grey.shade400,
            child: Icon(isActive ? Icons.check : Icons.circle, size: 9.r, color: Colors.white),
          ),
          SizedBox(height: 3.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.textMain : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive, Color color) {
    return Flexible(
      child: Container(
        height: 2.h,
        color: isActive ? color : Colors.grey.shade300,
      ),
    );
  }


  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22.r),
            SizedBox(height: 6.h),
            Text(
              '$count',
              style: TextStyle(color: color, fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMain, fontSize: 10.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    final initialName = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!
        : ((user?.username != null && user!.username!.isNotEmpty) ? user!.username! : 'عميل Bola Designs');
    final initialPhone = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : '';

    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    File? selectedPhoto;
    Uint8List? selectedPhotoBytes;
    String? selectedPhotoName;

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
                          final picked = await pickImageFile();
                          if (picked != null) {
                            setModalState(() {
                              selectedPhotoBytes = picked.bytes;
                              selectedPhotoName = picked.name;
                              selectedPhoto = picked.file;
                            });
                          }
                        },
                        child: Builder(
                          builder: (context) {
                            final editAvatarImg = selectedPhotoBytes != null
                                ? MemoryImage(selectedPhotoBytes!) as ImageProvider
                                : (selectedPhoto != null
                                    ? FileImage(selectedPhoto!) as ImageProvider
                                    : user?.getProfileImageProvider(authProvider.baseUrl));
                            return CircleAvatar(
                              radius: 40.r,
                              backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                              backgroundImage: editAvatarImg,
                              onBackgroundImageError: editAvatarImg != null ? (_, __) {} : null,
                              child: editAvatarImg == null
                                  ? const Icon(Icons.camera_alt, color: AppColors.primaryAccent)
                                  : null,
                            );
                          },
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
                          photoBytes: selectedPhotoBytes,
                          photoName: selectedPhotoName,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث البيانات بنجاح!'),
                              backgroundColor: AppColors.emeraldGreen,
                            ),
                          );
                          setState(() {});
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

    _pendingCount = combinedOrdersList.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      return st == 'pending' || st == 'pending_approval';
    }).length;

    _preparingCount = combinedOrdersList.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      return st == 'preparing' || st == 'in_progress' || st == 'processing' || st == 'approved';
    }).length;

    _readyCount = combinedOrdersList.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      return st == 'ready' || st == 'delivering';
    }).length;

    _completedCount = combinedOrdersList.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      return st == 'completed' || st == 'done' || st == 'delivered';
    }).length;

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
                              Builder(
                                builder: (context) {
                                  final mainAvatarImg = currentUser?.getProfileImageProvider(authProvider.baseUrl);
                                  return CircleAvatar(
                                    radius: 36.r,
                                    backgroundColor: AppColors.primaryAccent.withOpacity(0.08),
                                    backgroundImage: mainAvatarImg,
                                    onBackgroundImageError: mainAvatarImg != null ? (_, __) {} : null,
                                    child: mainAvatarImg == null
                                        ? Icon(Icons.person_rounded, size: 40.r, color: AppColors.primaryAccent)
                                        : null,
                                  );
                                },
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        final txt = currentUser?.displayName ?? 'مستخدم Bola';
                                        copyToClipboard(context, txt, label: 'اسم المستخدم');
                                      },
                                      borderRadius: BorderRadius.circular(6.r),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              currentUser?.displayName ?? 'مستخدم Bola',
                                              style: AppStyles.titleMedium.copyWith(fontSize: 18.sp),
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                          Icon(Icons.copy_rounded, size: 14.r, color: AppColors.primaryAccent),
                                        ],
                                      ),
                                    ),
                                    if (currentUser?.email != null && currentUser!.email!.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      InkWell(
                                        onTap: () => copyToClipboard(context, currentUser!.email!, label: 'البريد الإلكتروني'),
                                        borderRadius: BorderRadius.circular(6.r),
                                        child: Text(currentUser.email!, style: AppStyles.bodyMuted),
                                      ),
                                    ],
                                    if (currentUser?.phone != null && currentUser!.phone!.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      InkWell(
                                        onTap: () => copyToClipboard(context, currentUser!.phone!, label: 'رقم الهاتف'),
                                        borderRadius: BorderRadius.circular(6.r),
                                        child: Text(currentUser.phone!, style: AppStyles.bodyMuted),
                                      ),
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
                              if (combinedOrdersList.isNotEmpty)
                                InkWell(
                                  onTap: () => _showOrdersModal(context, filterTitle: isStaff ? 'جميع الطلبات' : 'جميع طلباتي'),
                                  child: Text(
                                    'عرض الكل >',
                                    style: AppStyles.bodyMuted.copyWith(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 12.sp),
                                  ),
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
                              itemCount: combinedOrdersList.length > 5 ? 5 : combinedOrdersList.length,
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
                                IconData statusIcon = Icons.hourglass_top_rounded;

                                if (status == 'preparing' || status == 'in_progress' || status == 'processing' || status == 'approved') {
                                  statusLabel = 'جاري التجهيز';
                                  statusColor = Colors.blueAccent;
                                  statusIcon = Icons.precision_manufacturing_rounded;
                                } else if (status == 'ready') {
                                  statusLabel = 'جاهز للتوصيل';
                                  statusColor = Colors.purpleAccent;
                                  statusIcon = Icons.local_shipping_rounded;
                                } else if (status == 'completed' || status == 'done' || status == 'delivered') {
                                  statusLabel = 'مكتمل';
                                  statusColor = AppColors.emeraldGreen;
                                  statusIcon = Icons.task_alt_rounded;
                                } else if (status == 'rejected') {
                                  statusLabel = 'مرفوض';
                                  statusColor = AppColors.dangerStart;
                                  statusIcon = Icons.error_outline_rounded;
                                }

                                return InkWell(
                                  onTap: () => _showOrdersModal(context, filterTitle: 'تفاصيل أوردر #$id'),
                                  borderRadius: BorderRadius.circular(14.r),
                                  child: Container(
                                    padding: EdgeInsets.all(12.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBg,
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16.r,
                                          backgroundColor: statusColor.withOpacity(0.15),
                                          child: Icon(statusIcon, color: statusColor, size: 16.r),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
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
                                              SizedBox(height: 2.h),
                                              Text(
                                                itemsSummary.isNotEmpty ? itemsSummary : 'تفاصيل الأوردر',
                                                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (date.isNotEmpty)
                                                Text(date, style: TextStyle(color: AppColors.textMuted, fontSize: 9.5.sp)),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
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
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                      SizedBox(height: 16.h),

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
                            icon: Icons.description_outlined,
                            title: 'الشروط والأحكام',
                            onTap: () => _showTermsDialog(context),
                          ),
                          const Divider(color: AppColors.borderLight, height: 1),
                          _buildListTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'سياسة الخصوصية',
                            onTap: () => _showPrivacyDialog(context),
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

                    // Logout Button with Confirmation Dialog to prevent accidental logout
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: AppColors.cardBg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                            title: const Text('تأكيد تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text('هل أنت متاكد من رغبتك في تسجيل الخروج من التطبيق؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerStart),
                                onPressed: () async {
                                  Navigator.of(dialogCtx).pop();
                                  await authProvider.logout();
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: const Text('تأكيد الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
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

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.description_rounded, color: AppColors.primaryAccent, size: 22.r),
                      ),
                      SizedBox(width: 10.w),
                      Text('الشروط والأحكام', style: AppStyles.titleMedium),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderLight, height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegalSection(
                        title: '📜 1. التخصيص والطباعة',
                        content: 'جميع المنتجات (المجات الحرارية، البراويز، والبلاكات) تُنفذ خصيصاً بناءً على الصور والأسماء المدخلة من العميل. يُرجى التأكد من دقة البيانات المدخلة قبل التأكيد النهائي.',
                      ),
                      _buildLegalSection(
                        title: '💳 2. طرق الدفع والاعتماد',
                        content: 'يتم اعتماد الطلبات ودخولها مرحلة التجهيز والتنفيذ فور مراجعة وتأكيد التحويل (إنستاباي / كاش / محفظة) من قِبل إدارة التطبيق.',
                      ),
                      _buildLegalSection(
                        title: '🚀 3. التوصيل والتسليم',
                        content: 'نلتزم بتنفيذ وتجهيز جميع طلبات Bola Designs بأعلى معايير الدقة والطباعة، وشحنها للتسليم في أسرع موعد متاح.',
                      ),
                      _buildLegalSection(
                        title: '🔄 4. سياسة الإرجاع',
                        content: 'نظرًا لطبيعة المنتجات المخصصة بالصور والأسماء الشخصية، يقتصر الإرجاع والاستبدال على وجود خطأ في الطباعة أو تلف أثناء الشحن والنقل.',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                child: const Text('موافق وفهمت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.security_rounded, color: AppColors.primaryAccent, size: 22.r),
                      ),
                      SizedBox(width: 10.w),
                      Text('سياسة الخصوصية', style: AppStyles.titleMedium),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderLight, height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegalSection(
                        title: '🛡️ 1. حماية البيانات الشخصية',
                        content: 'نلتزم بحماية بياناتك الشخصية (الاسم ورقم التواصل) ولا يتم مشاركتها إطلاقاً مع أي أطراف غير مخولة.',
                      ),
                      _buildLegalSection(
                        title: '🖼️ 2. خصوصية الصور والملفات المرفوعة',
                        content: 'جميع الصور والتصاميم المرفوعة من العميل تُستخدم حصرياً لإتمام عملية الطباعة والتجهيز الخاصة بطلبه فقط، وتتمتع بحماية كاملة.',
                      ),
                      _buildLegalSection(
                        title: '💳 3. أمان التحويلات المالية',
                        content: 'إيصالات التحويل وإثباتات الدفع تُراجع بأعلى مستويات الأمان لمراجعة الحسابات وتأكيد الطلب فقط دون حفظ بيانات بنكية حساسة.',
                      ),
                      _buildLegalSection(
                        title: '📩 4. التواصل والعروض المخصصة',
                        content: 'تُستخدم بياناتك لإرسال تحديثات حالة الطلب والعروض الحصرية المخصصة لك داخل التطبيق فقط.',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                child: const Text('موافق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalSection({required String title, required String content}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.labelBold.copyWith(fontSize: 13.sp, color: AppColors.primaryAccent)),
          SizedBox(height: 6.h),
          Text(content, style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp, height: 1.4)),
        ],
      ),
    );
  }
}
