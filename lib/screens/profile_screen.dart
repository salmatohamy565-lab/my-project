import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/web_file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/radial_background.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/app_logo_bar.dart';
import '../services/api_service.dart';
import '../widgets/payment_methods_modal.dart';
import 'login_screen.dart';
import 'admin/archived_tasks_screen.dart';
import 'admin/archived_files_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCustomerOrders();
  }

  Future<void> _fetchCustomerOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingOrders = true);
    try {
      final res = await _apiService.getOrders();
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> data = res.data ?? [];
        setState(() {
          _rawOrders = data;
          _pendingCount = data.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'pending').length;
          _preparingCount = data.where((o) {
            final st = (o['status'] ?? '').toString().toLowerCase();
            return st == 'preparing' || st == 'in_progress' || st == 'processing';
          }).length;
          _readyCount = data.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'ready').length;
          _completedCount = data.where((o) {
            final st = (o['status'] ?? '').toString().toLowerCase();
            return st == 'completed' || st == 'done';
          }).length;
          _isLoadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
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
        List<dynamic> filtered = _rawOrders;
        if (filterStatus != null) {
          filtered = _rawOrders.where((o) {
            final st = (o['status'] ?? '').toString().toLowerCase();
            if (filterStatus == 'pending') return st == 'pending';
            if (filterStatus == 'preparing') return st == 'preparing' || st == 'in_progress' || st == 'processing';
            if (filterStatus == 'ready') return st == 'ready';
            if (filterStatus == 'completed') return st == 'completed' || st == 'done';
            return true;
          }).toList();
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    filterTitle ?? 'طلباتي',
                    style: AppStyles.titleMedium.copyWith(fontSize: 18.sp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderLight),
              SizedBox(height: 12.h),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد طلبات في هذه الحالة حالياً',
                          style: AppStyles.bodyMuted,
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final id = item['id'] ?? 0;
                          final status = (item['status'] ?? 'pending').toString();
                          final total = item['total_price'] ?? item['total'] ?? 0;
                          final date = item['created_at'] != null
                              ? item['created_at'].toString().split('T').first
                              : '';

                          String statusLabel = 'قيد الموافقة';
                          Color statusColor = Colors.amber;

                          if (status == 'preparing' || status == 'in_progress') {
                            statusLabel = 'قيد التنفيذ';
                            statusColor = Colors.blueAccent;
                          } else if (status == 'ready') {
                            statusLabel = 'جاهز للتسليم';
                            statusColor = Colors.purpleAccent;
                          } else if (status == 'completed' || status == 'done') {
                            statusLabel = 'مكتمل';
                            statusColor = AppColors.emeraldGreen;
                          } else if (status == 'rejected') {
                            statusLabel = 'مرفوض';
                            statusColor = AppColors.dangerStart;
                          }

                          final itemsSummary = (item['items_summary'] ?? '').toString();
                          final rejectionReason = (item['rejection_reason'] ?? '').toString();

                          return Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20.r,
                                      backgroundColor: statusColor.withOpacity(0.15),
                                      child: Icon(Icons.receipt_long, color: statusColor, size: 20.r),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('طلب رقم #$id', style: AppStyles.labelBold),
                                          if (date.isNotEmpty) ...[
                                            SizedBox(height: 2.h),
                                            Text(date, style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(color: statusColor, fontSize: 11.sp, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text('$total ج.م', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent)),
                                      ],
                                    ),
                                  ],
                                ),
                                if (itemsSummary.isNotEmpty) ...[
                                  SizedBox(height: 8.h),
                                  Text('المنتجات: $itemsSummary', style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp)),
                                ],
                                if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
                                  SizedBox(height: 8.h),
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerStart.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: AppColors.dangerStart.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: AppColors.dangerStart, size: 16),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Text(
                                            'سبب الرفض: $rejectionReason',
                                            style: TextStyle(color: AppColors.dangerStart, fontSize: 11.sp, fontWeight: FontWeight.bold),
                                          ),
                                        ),
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
        : ((user?.username != null && user!.username!.isNotEmpty) ? user!.username! : 'salma');
    final initialPhone = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : '01271122860';

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
                        child: CircleAvatar(
                          radius: 40.r,
                          backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                          backgroundImage: selectedPhotoBytes != null
                              ? MemoryImage(selectedPhotoBytes!) as ImageProvider
                              : (selectedPhoto != null
                                  ? FileImage(selectedPhoto!) as ImageProvider
                                  : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                      ? NetworkImage(user.photoUrl!.startsWith('http')
                                          ? user.photoUrl!
                                          : '${authProvider.baseUrl}${user.photoUrl}') as ImageProvider
                                      : null)),
                          child: (selectedPhotoBytes == null && selectedPhoto == null && (user?.photoUrl == null || user!.photoUrl!.isEmpty))
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
    final currentUser = authProvider.currentUser;
    final bool isAdmin = currentUser?.isAdmin ?? false;
    final bool isCustomer = !isAdmin && !(currentUser?.isEmployee ?? false);

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(
              username: currentUser?.displayName ?? 'سلمى تهامي',
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
                                      currentUser?.displayName ?? 'سلمى تهامي',
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

                    // Order Status Tracker Card (قيد الموافقة، قيد التنفيذ، جاهز، مكتمل)
                    if (isCustomer) ...[
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
                                    Icon(Icons.inventory_2_outlined, color: AppColors.primaryAccent, size: 20.r),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'حالة الطلبات',
                                      style: AppStyles.titleMedium.copyWith(fontSize: 16.sp),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () => _showOrdersModal(context, filterTitle: 'جميع طلباتي'),
                                  child: Text(
                                    'عرض الكل >',
                                    style: AppStyles.bodyMuted.copyWith(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 12.sp),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'قيد الموافقة',
                                    count: _pendingCount,
                                    icon: Icons.hourglass_top_rounded,
                                    color: Colors.amber,
                                    onTap: () => _showOrdersModal(context, filterStatus: 'pending', filterTitle: 'طلبات قيد الموافقة'),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'قيد التنفيذ',
                                    count: _preparingCount,
                                    icon: Icons.build_circle_outlined,
                                    color: Colors.blueAccent,
                                    onTap: () => _showOrdersModal(context, filterStatus: 'preparing', filterTitle: 'طلبات قيد التنفيذ'),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'جاهز',
                                    count: _readyCount,
                                    icon: Icons.local_shipping_outlined,
                                    color: Colors.purpleAccent,
                                    onTap: () => _showOrdersModal(context, filterStatus: 'ready', filterTitle: 'طلبات جاهزة للتسليم'),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'مكتمل',
                                    count: _completedCount,
                                    icon: Icons.check_circle_outline_rounded,
                                    color: AppColors.emeraldGreen,
                                    onTap: () => _showOrdersModal(context, filterStatus: 'completed', filterTitle: 'طلبات مكتملة'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

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
                          if (isCustomer) ...[
                            _buildListTile(
                              icon: Icons.account_balance_wallet,
                              title: 'طرق الدفع والتحويل (كاش / انستاباي)',
                              onTap: () => PaymentMethodsModal.show(context),
                            ),
                            const Divider(color: AppColors.borderLight, height: 1),
                          ],
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
