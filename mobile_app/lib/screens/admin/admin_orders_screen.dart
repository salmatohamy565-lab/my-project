import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/product_image_widget.dart';

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
  List<OrderModel> _deliveredOrders = [];
  List<OrderModel> _rejectedOrders = [];
  bool _isLoading = false;
  final Set<int> _updatingOrderIds = {};
  StreamSubscription<List<Map<String, dynamic>>>? _ordersStreamSubscription;

  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrders();
    _initRealtimeStream();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchOrders();
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _ordersStreamSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initRealtimeStream() {
    try {
      _ordersStreamSubscription = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .listen((_) {
        if (!mounted) return;
        try {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.vibrate();
        } catch (_) {}
        _fetchOrders();
      }, onError: (err) {
        print('[ADMIN REALTIME ORDERS NOTICE] Stream error: $err');
      });
    } catch (e) {
      print('[ADMIN REALTIME ORDERS NOTICE] Setup error: $e');
    }
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    if (_pendingOrders.isEmpty && _preparingOrders.isEmpty && _readyOrders.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      final res = await _apiService.getOrders(
        status: 'all',
        userId: currentUser?.id,
        userPhone: currentUser?.phone,
        userName: currentUser?.username ?? currentUser?.name,
        isStaff: true,
      );
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> allData = res.data is List ? res.data : [];
        final List<OrderModel> allOrders = allData.map((e) => OrderModel.fromJson(e)).toList();

        setState(() {
          _pendingOrders = allOrders.where((o) {
            final st = o.status.toLowerCase();
            return st == 'pending' || st == 'pending_approval';
          }).toList();

          _preparingOrders = allOrders.where((o) {
            final st = o.status.toLowerCase();
            return st == 'preparing' || st == 'in_progress' || st == 'processing' || st == 'approved';
          }).toList();

          _readyOrders = allOrders.where((o) {
            final st = o.status.toLowerCase();
            return st == 'ready' || st == 'delivering';
          }).toList();

          _deliveredOrders = allOrders.where((o) {
            final st = o.status.toLowerCase();
            return st == 'delivered' || st == 'completed' || st == 'done';
          }).toList();

          _rejectedOrders = allOrders.where((o) {
            final st = o.status.toLowerCase();
            return st == 'rejected' || st == 'cancelled';
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ADMIN FETCH ORDERS ERROR] $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(OrderModel order, String newStatus, {String? reason}) async {
    if (newStatus.isEmpty || !['pending_approval', 'preparing', 'delivering', 'completed', 'cancelled', 'rejected', 'ready', 'delivered'].contains(newStatus)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حالة غير صالحة'), backgroundColor: AppColors.dangerStart),
        );
      }
      return;
    }

    if (_updatingOrderIds.contains(order.id)) {
      return; // Double-tap protection
    }

    // 1. INSTANT OPTIMISTIC UI UPDATE (0ms delay)
    final updatedOrder = OrderModel(
      id: order.id,
      userId: order.userId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      productIds: order.productIds,
      itemsSummary: order.itemsSummary,
      products: order.products,
      status: newStatus,
      totalPrice: order.totalPrice,
      paymentMethod: order.paymentMethod,
      paymentProofUrl: order.paymentProofUrl,
      customerAddress: order.customerAddress,
      rejectionReason: reason ?? order.rejectionReason,
      createdAt: order.createdAt,
    );

    setState(() {
      _updatingOrderIds.add(order.id);
      _pendingOrders.removeWhere((o) => o.id == order.id);
      _preparingOrders.removeWhere((o) => o.id == order.id);
      _readyOrders.removeWhere((o) => o.id == order.id);
      _deliveredOrders.removeWhere((o) => o.id == order.id);
      _rejectedOrders.removeWhere((o) => o.id == order.id);

      if (newStatus == 'preparing') {
        _preparingOrders.insert(0, updatedOrder);
        _tabController.animateTo(1);
      } else if (newStatus == 'ready' || newStatus == 'delivering') {
        _readyOrders.insert(0, updatedOrder);
        _tabController.animateTo(2);
      } else if (newStatus == 'delivered' || newStatus == 'completed') {
        _deliveredOrders.insert(0, updatedOrder);
        _tabController.animateTo(3);
      } else if (newStatus == 'rejected') {
        _rejectedOrders.insert(0, updatedOrder);
        _tabController.animateTo(4);
      }
    });

    String msg = '';
    Color bg = AppColors.emeraldGreen;

    if (newStatus == 'preparing') {
      msg = '✓ تمت الموافقة على الطلب #${order.id} وتحويله لقيد التجهيز';
      bg = AppColors.emeraldGreen;
    } else if (newStatus == 'ready' || newStatus == 'delivering') {
      msg = '🚚 تم تحويل الطلب #${order.id} إلى جاهز للتوصيل';
      bg = Colors.blueAccent;
    } else if (newStatus == 'delivered' || newStatus == 'completed') {
      msg = '✅ تم تحديث حالة الطلب #${order.id} إلى تم التسليم';
      bg = AppColors.emeraldGreen;
    } else if (newStatus == 'rejected') {
      msg = '✖ تم رفض الطلب #${order.id} وتحويله للمرفوضة';
      bg = AppColors.dangerStart;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        duration: const Duration(seconds: 2),
      ),
    );

    // 2. Perform backend update & update OrderProvider
    try {
      if (mounted) {
        final success = await context.read<OrderProvider>().updateOrderStatus(order.id, newStatus, reason: reason);
        if (success && mounted) {
          _fetchOrders();
        }
      }
    } catch (e) {
      print('[BACKEND UPDATE NOTICE] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحديث الحالة: $e', textAlign: TextAlign.center),
            backgroundColor: AppColors.dangerStart,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrderIds.remove(order.id);
        });
      }
    }
  }

  void _showRejectDialog(OrderModel order) {
    final reasonController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text('رفض الطلب (طلب #${order.id})', style: AppStyles.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('يرجى كتابة سبب الرفض للعميل (نص إجباري سيظهر للعميل):', style: AppStyles.bodyDefault),
              SizedBox(height: 12.h),
              TextField(
                controller: reasonController,
                textAlign: TextAlign.right,
                maxLines: 2,
                onChanged: (_) {
                  if (errorMessage != null) {
                    setDialogState(() => errorMessage = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'مثال: صورة الإيصال غير واضحة / رقم العملية غير مطابق',
                  fillColor: AppColors.inputBg,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              if (errorMessage != null) ...[
                SizedBox(height: 8.h),
                Text(
                  errorMessage!,
                  style: TextStyle(color: AppColors.dangerStart, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = reasonController.text.trim();
                if (text.isEmpty) {
                  setDialogState(() {
                    errorMessage = '⚠️ يرجى إدخال سبب الرفض أولاً قبل المتابعة';
                  });
                  return;
                }
                Navigator.of(dialogCtx).pop();
                _updateStatus(order, 'rejected', reason: text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerStart,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: const Text('تأكيد الرفض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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
            print('[BASE64 IMAGE DECODE ERROR] $err');
            return const Center(child: Text('تعذر تحميل صورة الإيصال', style: TextStyle(color: Colors.white)));
          },
        );
      } catch (e) {
        print('[BASE64 PARSE ERROR] $e');
      }
    }
    return Image.network(
      cleanUrl,
      width: double.infinity,
      fit: fit,
      errorBuilder: (_, err, ___) {
        print('[NETWORK IMAGE LOAD ERROR] $err for $cleanUrl');
        return const Center(child: Text('تعذر تحميل صورة الإيصال', style: TextStyle(color: Colors.white)));
      },
    );
  }

  void _showImageZoom(String imageUrl, OrderModel order) {
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
                  Text('إثبات الدفع - طلب #${order.id}', style: AppStyles.labelBold),
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
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  color: Colors.black,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildReceiptImageWidget(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              if (order.status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showRejectDialog(order);
                        },
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        label: const Text('رفض', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _updateStatus(order, 'preparing');
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text('قبول وتجهيز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldGreen,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
                  child: const Text('إغلاق والمعاينة', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetailDialog(ProductModel product, OrderModel order) {
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
                    Text('السعر التقديري للمنتج:', style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp)),
                    Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                const Divider(color: AppColors.borderLight),
                SizedBox(height: 8.h),
                Text('بيانات العميل صاحب الطلب:', style: AppStyles.labelBold.copyWith(fontSize: 13.sp)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    const Icon(Icons.person_rounded, color: AppColors.primaryAccent, size: 18),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        order.customerName.isNotEmpty ? order.customerName : 'عميل التطبيق',
                        style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
                if (order.customerPhone.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, color: Colors.green, size: 18),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(order.customerPhone, style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
                      ),
                      IconButton(
                        onPressed: () => _makeCall(order.customerPhone),
                        icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                        tooltip: 'اتصال',
                      ),
                      IconButton(
                        onPressed: () => _openWhatsApp(order.customerPhone, order.id),
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.teal, size: 20),
                        tooltip: 'واتساب',
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text('إغلاق المعاينة', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (_) {}
  }

  Future<void> _openWhatsApp(String phone, int orderId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty) return;
    String formatted = cleanPhone.startsWith('0') ? '2$cleanPhone' : cleanPhone;
    final Uri url = Uri.parse('https://wa.me/$formatted?text=${Uri.encodeComponent("مرحباً بك من Bola Designs بخصوص الطلب رقم #$orderId")}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final orderProv = context.watch<OrderProvider>();

    // Combine provider orders with local state to ensure instant reactive UI updates
    final List<OrderModel> combinedOrders = List.from(_pendingOrders)
      ..addAll(_preparingOrders)
      ..addAll(_readyOrders)
      ..addAll(_deliveredOrders)
      ..addAll(_rejectedOrders);

    for (final po in orderProv.orders) {
      if (!combinedOrders.any((o) => o.id == po.id)) {
        combinedOrders.insert(0, po);
      }
    }

    final pendingList = combinedOrders.where((o) {
      final st = o.status.toLowerCase();
      return st == 'pending' || st == 'pending_approval';
    }).toList();

    final preparingList = combinedOrders.where((o) {
      final st = o.status.toLowerCase();
      return st == 'preparing' || st == 'in_progress' || st == 'processing' || st == 'approved';
    }).toList();

    final readyList = combinedOrders.where((o) {
      final st = o.status.toLowerCase();
      return st == 'ready' || st == 'delivering';
    }).toList();

    final deliveredList = combinedOrders.where((o) {
      final st = o.status.toLowerCase();
      return st == 'delivered' || st == 'completed' || st == 'done';
    }).toList();

    final rejectedList = combinedOrders.where((o) {
      final st = o.status.toLowerCase();
      return st == 'rejected' || st == 'cancelled';
    }).toList();

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('إدارة وتتبع الطلبات (Orders Cycle)', style: AppStyles.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryAccent),
                          onPressed: _fetchOrders,
                          tooltip: 'تحديث الطلبات',
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Status Filter Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.primaryAccent,
                        unselectedLabelColor: AppColors.textMuted,
                        indicatorColor: AppColors.primaryAccent,
                        indicatorWeight: 3,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                        tabs: const [
                          Tab(text: 'بانتظار الموافقة'),
                          Tab(text: 'قيد التجهيز'),
                          Tab(text: 'جاهز وتوصيل'),
                          Tab(text: 'تم التسليم'),
                          Tab(text: 'المرفوضة'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Tab Views
                    Expanded(
                      child: _isLoading && combinedOrders.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOrdersList(pendingList, showPendingActions: true, emptyMsg: 'لا توجد طلبات بانتظار الموافقة حالياً'),
                                _buildOrdersList(preparingList, showReadyStep: true, emptyMsg: 'لا توجد طلبات قيد التجهيز'),
                                _buildOrdersList(readyList, showDeliveredStep: true, emptyMsg: 'لا توجد طلبات جاهزة للتوصيل'),
                                _buildOrdersList(deliveredList, emptyMsg: 'لا توجد طلبات مكتملة ومسلمة حتى الآن'),
                                _buildOrdersList(rejectedList, emptyMsg: 'لا توجد طلبات مرفوضة'),
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

  Widget _buildOrdersList(
    List<OrderModel> orders, {
    bool showPendingActions = false,
    bool showReadyStep = false,
    bool showDeliveredStep = false,
    required String emptyMsg,
  }) {
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
          final proofUrl = order.getFullPaymentProofUrl(_apiService.baseUrl);

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
                    Row(
                      children: [
                        Text('طلب رقم #${order.id}', style: AppStyles.titleMedium.copyWith(color: AppColors.primaryAccent, fontSize: 17.sp)),
                        SizedBox(width: 8.w),
                        if (order.createdAt != null)
                          Text(
                            '${order.createdAt!.day}/${order.createdAt!.month} ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}',
                            style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp),
                          ),
                      ],
                    ),
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
                SizedBox(height: 12.h),

                // Customer Info with Call/WhatsApp Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: 18.r, color: AppColors.primaryAccent),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        order.customerName.isNotEmpty ? order.customerName : 'عميل التطبيق',
                        style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                    ),
                    if (order.customerPhone.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _makeCall(order.customerPhone),
                        icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'اتصال هاتفي',
                      ),
                      SizedBox(width: 12.w),
                      IconButton(
                        onPressed: () => _openWhatsApp(order.customerPhone, order.id),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.teal, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'تواصل واتساب',
                      ),
                    ],
                  ],
                ),
                if (order.customerPhone.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h, right: 24.w),
                    child: Text('هاتف العميل: ${order.customerPhone}', style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp)),
                  ),

                // 1. Full Delivery Address (Multiline without truncation)
                Builder(
                  builder: (_) {
                    final cleanAddress = order.extractedAddress.isNotEmpty
                        ? order.extractedAddress
                        : (order.customerAddress ?? '');
                    if (cleanAddress.isNotEmpty) {
                      return _buildInfoRow(
                        Icons.location_on_outlined,
                        'عنوان التوصيل بالكامل',
                        cleanAddress,
                        allowMultiLine: true,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // 2. Dedicated Prominent Transfer Phone Card
                Builder(
                  builder: (_) {
                    final transferNumber = order.extractedTransferPhone;
                    if (transferNumber.isNotEmpty) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6.h),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryAccent, size: 16.r),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'رقم محفظة / هاتف التحويل:',
                                    style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    transferNumber,
                                    style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 14.sp, letterSpacing: 1.1),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _copyToClipboard(transferNumber, 'رقم التحويل'),
                              icon: Icon(Icons.copy_rounded, color: AppColors.primaryAccent, size: 18.r),
                              tooltip: 'نسخ رقم التحويل',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(4.r),
                            ),
                            SizedBox(width: 6.w),
                            IconButton(
                              onPressed: () => _makeCall(transferNumber),
                              icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                              tooltip: 'اتصال',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(4.r),
                            ),
                            SizedBox(width: 6.w),
                            IconButton(
                              onPressed: () => _openWhatsApp(transferNumber, order.id),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.teal, size: 18),
                              tooltip: 'واتساب',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(4.r),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                SizedBox(height: 6.h),
                _buildInfoRow(Icons.shopping_bag_outlined, 'المنتجات والكميات', order.itemsSummary.isNotEmpty ? order.itemsSummary : 'طلب منتجات', allowMultiLine: true),

                if (order.products.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text('المنتجات المطلوبة (انقر لمعاينة الصورة بالتفصيل 🔍):', style: AppStyles.labelBold.copyWith(fontSize: 11.sp)),
                  SizedBox(height: 6.h),
                  SizedBox(
                    height: 68.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: order.products.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, pIdx) {
                        final prod = order.products[pIdx];
                        return InkWell(
                          onTap: () => _showProductDetailDialog(prod, order),
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            width: 170.w,
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: SizedBox(
                                    width: 44.w,
                                    height: 44.h,
                                    child: ProductImageWidget(
                                      imageUrl: prod.imageUrl,
                                      baseUrl: _apiService.baseUrl,
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
                                        style: TextStyle(color: AppColors.textMain, fontSize: 11.sp, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${prod.price.toStringAsFixed(0)} ج.م',
                                        style: TextStyle(color: AppColors.primaryAccent, fontSize: 10.sp, fontWeight: FontWeight.w600),
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
                ],

                _buildInfoRow(Icons.account_balance_wallet_outlined, 'إجمالي المبلغ', '${order.totalPrice.toStringAsFixed(0)} ج.م'),
                _buildInfoRow(Icons.payment_outlined, 'طريقة الدفع', order.paymentMethod?.toUpperCase() ?? 'INSTAPAY'),

                SizedBox(height: 10.h),
                // Dedicated Permanent Payment Receipt Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, color: AppColors.primaryAccent, size: 20.r),
                              SizedBox(width: 6.w),
                              Text('إيصال الدفع:', style: AppStyles.labelBold.copyWith(fontSize: 13.sp, color: AppColors.primaryAccent)),
                            ],
                          ),
                          if (proofUrl != null && proofUrl.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text('تم إرفاق الإيصال 🧾', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text('لم يتم إرفاق إيصال', style: TextStyle(color: Colors.orange.shade800, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      if (proofUrl != null && proofUrl.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _showImageZoom(proofUrl, order),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              height: 140.h,
                              color: Colors.black,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildReceiptImageWidget(proofUrl, fit: BoxFit.contain),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 6.w),
                                        Text('معاينة وتكبير صورة إيصال الدفع 🔍', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16.r),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'لا توجد صورة إيصال مرفقة لهذا الطلب (دفع كاش / محفظة بدون صورة)',
                                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.dangerStart.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.dangerStart.withOpacity(0.3)),
                    ),
                    child: Text('سبب الرفض الموضح للعميل: ${order.rejectionReason}', style: TextStyle(color: AppColors.dangerStart, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ],

                // Action Required Box for Pending Orders
                if (showPendingActions) ...[
                  SizedBox(height: 14.h),
                  const Divider(color: AppColors.borderLight),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(order),
                          icon: const Icon(Icons.close_rounded, color: Colors.red),
                          label: const Text('رفض الطلب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                          label: const Text('موافقة وتجهيز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emeraldGreen,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (showReadyStep) ...[
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

                if (showDeliveredStep) ...[
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, 'delivered'),
                    icon: const Icon(Icons.task_alt_rounded, color: Colors.white),
                    label: const Text('تأكيد التسليم للعميل (تم التسليم)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldGreen,
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ تم نسخ $label: $text', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.successStart,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool allowMultiLine = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: allowMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18.r, color: AppColors.textMuted),
          SizedBox(width: 8.w),
          Text('$label: ', style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp)),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.bold, fontSize: 13.sp),
              overflow: allowMultiLine ? TextOverflow.visible : TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade100;
      case 'preparing':
        return Colors.blue.shade100;
      case 'ready':
        return Colors.purple.shade100;
      case 'delivered':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade900;
      case 'preparing':
        return Colors.blue.shade900;
      case 'ready':
        return Colors.purple.shade900;
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
