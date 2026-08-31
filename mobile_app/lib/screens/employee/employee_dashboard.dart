import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/product_image_widget.dart';
import '../../widgets/product_details_modal.dart';
import '../products/products_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _selectedRecipientId;
  Timer? _refreshTimer;
  bool _isDownloading = false;
  String? _downloadingFilename;
  String _orderStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _refreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          _loadData();
        }
      });
    });
  }


  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    await Future.wait<void>([
      context.read<OrderProvider>().fetchOrders(status: _orderStatusFilter, currentUser: currentUser),
      context.read<TaskProvider>().fetchTasks(),
      context.read<UserProvider>().fetchUserFiles(currentUser.id),
      context.read<UserProvider>().fetchUsers(),
    ]);
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      if (kIsWeb) {
        setState(() {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
        });
      } else if (result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    }
  }

  Future<void> _sendFileToColleague() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    if (_selectedFile == null && _selectedFileBytes == null) {
      _showSnackbar('يرجى اختيار ملف أولاً قبل الإرسال', Colors.orange);
      return;
    }

    final userProvider = context.read<UserProvider>();
    final recipientId = _selectedRecipientId;

    final success = await userProvider.uploadUserFile(
      currentUser.id,
      file: _selectedFile,
      fileBytes: _selectedFileBytes,
      fileName: _selectedFileName,
      recipientId: recipientId,
    );

    if (success) {
      setState(() {
        _selectedFile = null;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _selectedRecipientId = null;
      });
      _showSnackbar(
        recipientId != null ? '✓ تم إرسال الملف للزميل بنجاح' : '✓ تم مشاركة الملف مع جميع الموظفين بنجاح',
        AppColors.successStart,
      );
      _loadData();
    } else {
      final error = userProvider.errorMessage ?? 'فشل إرسال الملف';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus, {String? reason}) async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.updateOrderStatus(orderId, newStatus, reason: reason);
    if (success) {
      _showSnackbar('✓ تم تحديث حالة الطلب بنجاح', AppColors.successStart);
      _loadData();
    } else {
      _showSnackbar(orderProvider.errorMessage ?? 'فشل تحديث الطلب', Colors.red);
    }
  }

  Future<void> _markTaskDone(int taskId) async {
    final success = await context.read<TaskProvider>().markTaskDone(taskId);
    if (success) {
      _showSnackbar('✓ تم إكمال المهمة بنجاح', AppColors.successStart);
      _loadData();
    } else {
      final error = context.read<TaskProvider>().errorMessage ?? 'فشل تحديث المهمة';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _downloadAndOpenFile(String fileUrl, String filename) async {
    setState(() {
      _isDownloading = true;
      _downloadingFilename = filename;
    });

    try {
      final apiService = ApiService();
      final fullUrl = fileUrl.startsWith('http') ? fileUrl : '${apiService.baseUrl}$fileUrl';

      if (kIsWeb) {
        final uri = Uri.parse(fullUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          _isDownloading = false;
          _downloadingFilename = null;
        });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$filename';
      final dio = Dio();

      await dio.download(
        fullUrl,
        savePath,
        options: Options(
          headers: apiService.cookie != null ? {'Cookie': apiService.cookie} : null,
        ),
      );

      setState(() {
        _isDownloading = false;
        _downloadingFilename = null;
      });

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        _showSnackbar('تم التحميل: ${result.message}', Colors.amber);
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadingFilename = null;
      });
      _showSnackbar('حدث خطأ أثناء فتح الملف', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final userProvider = context.watch<UserProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser != null && currentUser.isCustomer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProductsScreen()),
          );
        }
      });
    }

    final orders = orderProvider.orders;
    final tasks = taskProvider.tasks;
    final files = userProvider.userFiles;
    final allUsers = userProvider.users;

    // Filter colleagues (exclude current user)
    final colleagues = allUsers.where((u) {
      if (u.id == currentUser?.id) return false;
      final r = u.role.toLowerCase();
      final un = u.username.toLowerCase();
      return r == 'employee' || r == 'admin' || r == 'owner' || r == 'supervisor' || un.startsWith('emp_') || un.startsWith('admin_');
    }).toList();


    return Scaffold(
      key: _scaffoldKey,
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: currentUser?.username ?? 'الموظف'),

            // Employee Banner & Custom Tabs
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: const Icon(Icons.badge_outlined, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'لوحة التحكم الخاصة بالموظفين',
                                style: AppStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'تبادل الملفات مع الزملاء، وإنجاز المهام',
                                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Modern Segmented Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp),
                      tabs: const [
                        Tab(text: '📦 طلبات العملاء'),
                        Tab(text: '📝 المهام'),
                        Tab(text: '📁 الملفات'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Orders Processing
                  _buildOrdersTab(context.watch<OrderProvider>().orders, context.read<OrderProvider>(), ApiService().baseUrl),

                  // Tab 2: Tasks
                  _buildTasksTab(tasks, taskProvider),

                  // Tab 3: Inter-Employee File Sharing
                  _buildFileSharingTab(files, colleagues, currentUser?.id),
                ],
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentRoute: 'employee_dashboard',
        isAdmin: currentUser?.isAdmin ?? false,
      ),
    );
  }

  // ===================== Tab 1: Orders Processing =====================
  Widget _buildOrdersTab(List<OrderModel> orders, OrderProvider orderProvider, String baseUrl) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Status Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', 'all'),
                  _buildFilterChip('⏳ قيد الانتظار', 'pending'),
                  _buildFilterChip('⚙️ قيد التجهيز', 'preparing'),
                  _buildFilterChip('🚚 جاهز للاستلام', 'ready'),
                  _buildFilterChip('❌ مرفوض', 'rejected'),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            if (orderProvider.isLoading && orders.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
              )
            else if (orders.isEmpty)
              _buildEmptyCard(Icons.shopping_bag_outlined, 'لا توجد طلبات واردة بهذه الحالة حالياً')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (ctx, idx) {
                  final order = orders[idx];
                  return _buildOrderCard(order, baseUrl);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _orderStatusFilter == value;
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primaryAccent,
        backgroundColor: AppColors.cardBg,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _orderStatusFilter = value;
            });
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, String baseUrl) {
    Color statusColor;
    String statusText;

    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = '⏳ قيد الانتظار';
        break;
      case 'preparing':
      case 'approved':
        statusColor = Colors.blue;
        statusText = '⚙️ جاري التجهيز';
        break;
      case 'ready':
        statusColor = Colors.teal;
        statusText = '🚚 جاهز للاستلام';
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = '✅ تم التسليم';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = '❌ مرفوض';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status;
    }

    final proofUrl = order.getFullPaymentProofUrl(baseUrl);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طلب #${order.id}',
                style: AppStyles.titleSmall.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11.sp),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 20),

          // Order Details
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.primaryAccent),
              SizedBox(width: 6.w),
              Text('العميل: ', style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp)),
              Text(order.customerName, style: AppStyles.labelBold.copyWith(fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: Colors.green),
              SizedBox(width: 6.w),
              Text('الهاتف: ', style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp)),
              Expanded(
                child: Text(
                  order.customerPhone.isEmpty ? 'غير محدد' : order.customerPhone,
                  style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ),
              if (order.customerPhone.isNotEmpty) ...[
                IconButton(
                  onPressed: () => _makeCall(order.customerPhone),
                  icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'اتصال هاتفي ورنة على التليفون',
                ),
                SizedBox(width: 10.w),
                IconButton(
                  onPressed: () => _openWhatsApp(order.customerPhone, order.id),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.teal, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'مراسلة واتساب',
                ),
              ],
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primaryAccent),
              SizedBox(width: 6.w),
              Text('المنتجات: ', style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp)),
              Expanded(
                child: Text(
                  order.itemsSummary.isEmpty ? 'طلب مخصص' : order.itemsSummary,
                  style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (order.products.isNotEmpty) ...[
            SizedBox(height: 8.h),
            SizedBox(
              height: 54.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.products.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, pIdx) {
                  final prod = order.products[pIdx];
                  return InkWell(
                    onTap: () => ProductDetailsModal.show(context, prod),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 150.w,
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
                              width: 38.w,
                              height: 38.h,
                              child: ProductImageWidget(
                                imageUrl: prod.imageUrl,
                                baseUrl: baseUrl,
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
          ],
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: AppColors.successStart),
                  SizedBox(width: 6.w),
                  Text(
                    '${order.totalPrice.toStringAsFixed(2)} ج.م',
                    style: TextStyle(color: AppColors.successStart, fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                ],
              ),
              if (proofUrl != null)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.network(proofUrl, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 16, color: AppColors.primaryAccent),
                  label: Text('معاينة الإثبات', style: TextStyle(color: AppColors.primaryAccent, fontSize: 11.sp)),
                ),
            ],
          ),

          // Employee Action Buttons
          const Divider(color: AppColors.borderLight, height: 20),
          Row(
            children: [
              if (order.status == 'pending' || order.status == 'pending_approval') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(order.id, 'preparing'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                    label: const Text('قبول وتجهيز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryAccent,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(order.id, 'rejected', reason: 'إثبات غير مكتمل'),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                    label: const Text('رفض الطلب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ] else if (order.status == 'preparing' || order.status == 'approved') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(order.id, 'ready'),
                    icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 16),
                    label: const Text('تأكيد الجاهزية للاستلام 🚚', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ] else if (order.status == 'ready') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(order.id, 'delivered'),
                    icon: const Icon(Icons.task_alt, color: Colors.white, size: 16),
                    label: const Text('تأكيد التسليم للعميل ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'تم معالجة هذا الطلب',
                      style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===================== Tab 2: Inter-Employee File Sharing =====================
  Widget _buildFileSharingTab(List<dynamic> files, List<UserModel> colleagues, int? currentUserId) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Send File to Colleague Card
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3), width: 1.5),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                      SizedBox(width: 10.w),
                      Text('إرسال ملف لزميل عمل', style: AppStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: AppColors.borderLight, height: 20),

                  // Select Recipient Dropdown
                  Text('اختر الزميل المستقبل:', style: AppStyles.labelBold.copyWith(fontSize: 12.sp)),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.borderDark, width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Builder(
                        builder: (context) {
                          final validRecipientId = colleagues.any((u) => u.id == _selectedRecipientId) ? _selectedRecipientId : null;

                          return DropdownButton<int?>(
                            value: validRecipientId,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.bold),
                            hint: Text(
                              'الجميع (مشاركة عامة مع كافة الموظفين)',
                              style: TextStyle(color: Colors.black87, fontSize: 12.sp, fontWeight: FontWeight.w600),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'الجميع (مشاركة عامة مع كافة الموظفين)',
                                  style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...colleagues.map((user) => DropdownMenuItem<int?>(
                                    value: user.id,
                                    child: Text(
                                      '👤 ${user.displayName} (@${user.username})',
                                      style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w600),
                                    ),
                                  )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedRecipientId = val;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Select File Box
                  InkWell(
                    onTap: _selectFile,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        border: Border.all(color: AppColors.borderDark),
                        borderRadius: AppStyles.inputRadius,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_rounded, color: AppColors.primaryAccent),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _selectedFileName ?? 'اختر ملف تصاميم/مستند للإرسال',
                              style: TextStyle(
                                color: _selectedFileName != null ? Colors.white : AppColors.textMuted,
                                fontSize: 12.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  ElevatedButton.icon(
                    onPressed: _sendFileToColleague,
                    icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                    label: Text(
                      _selectedRecipientId != null && colleagues.any((u) => u.id == _selectedRecipientId)
                          ? 'إرسال إلى ${colleagues.firstWhere((u) => u.id == _selectedRecipientId).username}'
                          : 'مشاركة مع جميع الموظفين',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryAccent,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Received / Shared Files List
            Text('الملفات المشتركة والمستلمة من الزملاء', style: AppStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),

            if (files.isEmpty)
              _buildEmptyCard(Icons.folder_open, 'لا توجد ملفات مشتركة حالياً')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: files.length,
                itemBuilder: (ctx, idx) {
                  final f = files[idx];
                  final isMyUpload = f.uploadedById == currentUserId;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: isMyUpload
                                ? AppColors.primaryAccent.withOpacity(0.12)
                                : AppColors.successStart.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            isMyUpload ? Icons.upload_file : Icons.download_for_offline,
                            color: isMyUpload ? AppColors.primaryAccent : AppColors.successStart,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.filename,
                                style: AppStyles.labelBold.copyWith(fontSize: 13.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text(
                                    isMyUpload ? 'مرفوع بواسطتك' : 'مرسل من: ${f.uploadedBy}',
                                    style: TextStyle(
                                      color: isMyUpload ? AppColors.primaryAccent : AppColors.successStart,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (f.recipientName != null) ...[
                                    SizedBox(width: 8.w),
                                    Text(
                                      'إلى: ${f.recipientName}',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton.icon(
                          onPressed: _isDownloading && _downloadingFilename == f.filename
                              ? null
                              : () => _downloadAndOpenFile(f.url, f.filename),
                          icon: _isDownloading && _downloadingFilename == f.filename
                              ? SizedBox(width: 14.w, height: 14.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                          label: Text(
                            _isDownloading && _downloadingFilename == f.filename ? 'جاري..' : 'فتح',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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
    );
  }

  // ===================== Tab 3: Tasks =====================
  Widget _buildTasksTab(List<dynamic> tasks, TaskProvider taskProvider) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('المهام الإدارية والتشغيلية', style: AppStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),

            if (taskProvider.isLoading && tasks.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
              )
            else if (tasks.isEmpty)
              _buildEmptyCard(Icons.assignment_turned_in_outlined, 'لا توجد مهام مسندة إليك حالياً')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (ctx, idx) {
                  final task = tasks[idx];
                  final isDone = task.status == 'done';

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title, style: AppStyles.labelBold.copyWith(fontSize: 13.sp)),
                              SizedBox(height: 4.h),
                              Text(
                                task.description.isEmpty ? 'بدون تفاصيل إضافية' : task.description,
                                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        if (!isDone)
                          ElevatedButton(
                            onPressed: () => _markTaskDone(task.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successStart,
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                            child: Text('إكمال', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.successStart.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text('✓ مكتملة', style: TextStyle(color: AppColors.successStart, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(IconData icon, String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44.sp, color: AppColors.textMuted.withOpacity(0.5)),
          SizedBox(height: 10.h),
          Text(message, style: AppStyles.bodyMuted),
        ],
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
}
