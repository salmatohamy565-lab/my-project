import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _preparingOrders = [];
  List<OrderModel> _readyOrders = [];
  List<OrderModel> _rejectedOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final pendingRes = await _apiService.getOrders(status: 'pending');
      final preparingRes = await _apiService.getOrders(status: 'preparing');
      final readyRes = await _apiService.getOrders(status: 'ready');
      final rejectedRes = await _apiService.getOrders(status: 'rejected');

      if (mounted) {
        setState(() {
          _pendingOrders = (pendingRes.data as List).map((e) => OrderModel.fromJson(e)).toList();
          _preparingOrders = (preparingRes.data as List).map((e) => OrderModel.fromJson(e)).toList();
          _readyOrders = (readyRes.data as List).map((e) => OrderModel.fromJson(e)).toList();
          _rejectedOrders = (rejectedRes.data as List).map((e) => OrderModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(OrderModel order, String newStatus, {String? reason}) async {
    try {
      await _apiService.updateOrderStatus(order.id, newStatus, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'preparing'
                  ? '✓ تم قبول الطلب #${order.id} وتحويله لقيد التجهيز'
                  : '✖ تم رفض الطلب #${order.id} وتحويله للطلبات المرفوضة',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: newStatus == 'preparing' ? AppColors.emeraldGreen : AppColors.dangerStart,
          ),
        );
        await _fetchOrders();
        if (newStatus == 'preparing') {
          _tabController.animateTo(1);
        } else if (newStatus == 'ready') {
          _tabController.animateTo(2);
        } else if (newStatus == 'rejected') {
          _tabController.animateTo(3);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.dangerStart),
        );
      }
    }
  }

  void _showRejectDialog(OrderModel order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('رفض إثبات الدفع (طلب #${order.id})', style: AppStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('يرجى توضيح سبب الرفض للعميل (اختياري):', style: AppStyles.bodyDefault),
            SizedBox(height: 10.h),
            TextField(
              controller: reasonController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'مثال: الصورة غير واضحة / المبلغ غير مكتمل',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateStatus(order, 'rejected', reason: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerStart),
            child: const Text('تأكيد الرفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showImageZoom(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.black,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Padding(
                  padding: EdgeInsets.all(20.r),
                  child: const Text('تعذر تحميل صورة الإيصال', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('إغلاق', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: user?.username ?? 'الأدمن'),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('إدارة الطلبات الحالية (Current Orders)', style: AppStyles.titleMedium),
                    SizedBox(height: 10.h),

                    // Status Filter Tabs
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
                          Tab(text: 'بانتظار الموافقة'),
                          Tab(text: 'قيد التجهيز'),
                          Tab(text: 'جاهز وتوصيل'),
                          Tab(text: 'المرفوضة'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Tab Views
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOrdersList(_pendingOrders, showActions: true, emptyMsg: 'لا توجد طلبات بانتظار الموافقة'),
                                _buildOrdersList(_preparingOrders, showNextStep: true, emptyMsg: 'لا توجد طلبات قيد التجهيز'),
                                _buildOrdersList(_readyOrders, emptyMsg: 'لا توجد طلبات مكتملة حالياً'),
                                _buildOrdersList(_rejectedOrders, emptyMsg: 'لا توجد طلبات مرفوضة'),
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
        currentRoute: 'admin_orders',
        isAdmin: true,
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {bool showActions = false, bool showNextStep = false, required String emptyMsg}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 54.sp, color: AppColors.textMuted),
            SizedBox(height: 10.h),
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
            margin: EdgeInsets.only(bottom: 14.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
              boxShadow: AppStyles.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('طلب رقم #${order.id}', style: AppStyles.titleMedium.copyWith(color: AppColors.primaryAccent, fontSize: 18.sp)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(order.status),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _getStatusLabel(order.status),
                        style: TextStyle(color: _getStatusTextColor(order.status), fontWeight: FontWeight.bold, fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Details List
                _buildInfoRow(Icons.person_outline, 'العميل', order.customerName.isNotEmpty ? order.customerName : 'عميل'),
                _buildInfoRow(Icons.phone_android_outlined, 'الهاتف', order.customerPhone.isNotEmpty ? order.customerPhone : 'غير محدد'),
                _buildInfoRow(Icons.shopping_bag_outlined, 'المنتجات', order.itemsSummary.isNotEmpty ? order.itemsSummary : 'منتجات الطلب'),
                _buildInfoRow(Icons.account_balance_wallet_outlined, 'الإجمالي', '${order.totalPrice.toStringAsFixed(0)} ج.م'),
                _buildInfoRow(Icons.payment_outlined, 'طريقة الدفع', order.paymentMethod?.toUpperCase() ?? 'INSTAPAY'),

                // Receipt/Proof Image Thumbnail
                if (order.getFullPaymentProofUrl(_apiService.baseUrl) != null) ...[
                  SizedBox(height: 12.h),
                  Text('إثبات الدفع (صورة الإيصال):', style: AppStyles.labelBold.copyWith(fontSize: 12.sp)),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () => _showImageZoom(order.getFullPaymentProofUrl(_apiService.baseUrl)!),
                    child: Container(
                      height: 110.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
                        color: Colors.black12,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            order.getFullPaymentProofUrl(_apiService.baseUrl)!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Text('تعذر تحميل المعاينة')),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                SizedBox(width: 4.w),
                                Text('انقر للتكبير والمراجعة', style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text('سبب الرفض: ${order.rejectionReason}', style: TextStyle(color: AppColors.dangerStart, fontSize: 12.sp)),
                ],

                // Action Required Box
                if (showActions) ...[
                  SizedBox(height: 14.h),
                  const Divider(color: AppColors.borderLight),
                  Center(
                    child: Text('مطلوب اتخاذ إجراء', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(order),
                          icon: const Icon(Icons.close_rounded, color: Colors.red),
                          label: const Text('رفض', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(order, 'preparing'),
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                          label: const Text('موافقة وتجهيز', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (showNextStep) ...[
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, 'ready'),
                    icon: const Icon(Icons.delivery_dining_rounded, color: Colors.white),
                    label: const Text('تحويل إلى جاهز للتوصيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18.r, color: AppColors.textMuted),
          SizedBox(width: 8.w),
          Text('$label: ', style: AppStyles.bodyMuted.copyWith(fontSize: 13.sp)),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.bold, fontSize: 13.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade100;
      case 'preparing':
        return Colors.blue.shade100;
      case 'ready':
      case 'delivered':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade900;
      case 'preparing':
        return Colors.blue.shade900;
      case 'ready':
      case 'delivered':
        return Colors.green.shade900;
      case 'rejected':
        return Colors.red.shade900;
      default:
        return Colors.black87;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'preparing':
        return 'جاري التجهيز';
      case 'ready':
        return 'جاهز للتوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
