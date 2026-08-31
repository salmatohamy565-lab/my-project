import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_logo_bar.dart';
import 'employee_detail_screen.dart';
import 'admin_orders_screen.dart';
import 'archived_tasks_screen.dart';
import 'archived_files_screen.dart';
import 'admin_files_screen.dart';
import '../../utils/copy_utils.dart';
import '../products/products_screen.dart';
import '../employee/employee_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  
  // Forms Controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();

  int? _selectedUserForTask;
  int? _selectedUserForFile;
  File? _selectedFile;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  Timer? _statsTimer;
  bool _isArchiving = false;
  String? _archiveMessage;

  final List<Map<String, dynamic>> _samplePaymentProofs = [
    {
      'id': 'TRX-101',
      'user_name': 'عميل بولا ديزاينز',
      'payment_method': 'انستاباي (InstaPay)',
      'amount': '150.00 ج.م',
      'sender_phone': '01228569626',
      'status': 'Payment Proof Submitted',
      'status_ar': 'إيصال مرفق للمراجعة ⏳',
      'timestamp': '2026-07-25 18:30',
      'is_verified': false,
    },
    {
      'id': 'TRX-102',
      'user_name': 'مؤسسة الدعاية والشركات',
      'payment_method': 'فودافون كاش',
      'amount': '380.00 ج.م',
      'sender_phone': '01001696249',
      'status': 'Payment Proof Submitted',
      'status_ar': 'إيصال مرفق للمراجعة ⏳',
      'timestamp': '2026-07-25 17:15',
      'is_verified': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // Start periodic status checking (every 5 seconds)
      _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          context.read<UserProvider>().fetchStats();
          context.read<UserProvider>().fetchUsers();
          context.read<TaskProvider>().fetchTasks();
        }
      });
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userProv = context.read<UserProvider>();
    final taskProv = context.read<TaskProvider>();
    final orderProv = context.read<OrderProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    await Future.wait([
      userProv.fetchStats(),
      userProv.fetchUsers(),
      taskProv.fetchTasks(),
      orderProv.fetchOrders(currentUser: currentUser),
      context.read<NotificationProvider>().fetchNotifications(currentUser: currentUser),
    ]);
  }


  Future<void> _createNewUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : '123456';

    if (username.isEmpty) {
      _showSnackbar('يرجى إدخال اسم المستخدم للموظف', Colors.red);
      return;
    }

    final success = await context.read<UserProvider>().createUser(username, password);
    if (success) {
      _usernameController.clear();
      _passwordController.clear();
      _showSnackbar('تم إنشاء الموظف بنجاح', AppColors.successStart);
    } else {
      final error = context.read<UserProvider>().errorMessage ?? 'فشل إنشاء الموظف';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _assignTask() async {
    final title = _taskTitleController.text.trim();
    final desc = _taskDescController.text.trim();

    if (title.isEmpty || _selectedUserForTask == null) {
      _showSnackbar('العنوان والموظف مطلوبان لإسناد المهمة', Colors.red);
      return;
    }

    final success = await context.read<TaskProvider>().createTask(title, desc, _selectedUserForTask!);
    if (success) {
      _taskTitleController.clear();
      _taskDescController.clear();
      setState(() {
        _selectedUserForTask = null;
      });
      _showSnackbar('تم إضافة المهمة بنجاح', AppColors.successStart);
    } else {
      final error = context.read<TaskProvider>().errorMessage ?? 'فشل إضافة المهمة';
      _showSnackbar(error, Colors.red);
    }
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

  Future<void> _uploadFile() async {
    if (_selectedUserForFile == null) {
      _showSnackbar('يرجى اختيار الموظف أولاً', Colors.red);
      return;
    }
    if (_selectedFile == null && _selectedFileBytes == null) {
      _showSnackbar('يرجى اختيار ملف للرفع', Colors.red);
      return;
    }

    final success = await context.read<UserProvider>().uploadUserFile(
      _selectedUserForFile!,
      file: _selectedFile,
      fileBytes: _selectedFileBytes,
      fileName: _selectedFileName,
    );
    if (success) {
      setState(() {
        _selectedFile = null;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _selectedUserForFile = null;
      });
      _showSnackbar('تم رفع الملف بنجاح', AppColors.successStart);
    } else {
      final error = context.read<UserProvider>().errorMessage ?? 'فشل رفع الملف';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _archiveCompletedTasks() async {
    setState(() {
      _isArchiving = true;
      _archiveMessage = 'جارٍ الأرشفة...';
    });

    final archivedCount = await context.read<TaskProvider>().archiveCompletedTasks();
    
    if (mounted) {
      setState(() {
        _isArchiving = false;
        if (archivedCount != null) {
          _archiveMessage = 'تم أرشفة $archivedCount مهمة مكتملة';
        } else {
          _archiveMessage = 'فشل الأرشفة';
        }
      });
      _showSnackbar(_archiveMessage!, AppColors.primaryAccent);
    }
  }

  void _confirmDeleteUser(int userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.loginCardBg,
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: Text('هل أنت متأكد أنك تريد حذف الموظف "$name"؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context.read<UserProvider>().deleteUser(userId);
              if (success) {
                _showSnackbar('تم حذف الموظف بنجاح', AppColors.successStart);
              } else {
                _showSnackbar('فشل حذف الموظف', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerStart),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
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
    final userProvider = context.watch<UserProvider>();
    final taskProvider = context.watch<TaskProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser != null && !currentUser.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ProductsScreen()),
          );
        }
      });
    }

    final stats = userProvider.stats;
    final staffList = userProvider.users;
    final activeTasks = taskProvider.tasks;

    final supervisorsOnly = staffList.where((u) {
      final r = u.role.toLowerCase();
      final un = u.username.toLowerCase();
      return r == 'employee' || r == 'admin' || r == 'owner' || r == 'supervisor' || un.startsWith('emp_') || un.startsWith('admin_');
    }).toList();

    final Set<String> uniqueEmpSet = {};
    for (final u in staffList) {
      final r = u.role.toLowerCase();
      final un = u.username.toLowerCase();
      if (r == 'employee' || r == 'supervisor' || un.startsWith('emp_')) {
        if (un.contains('salma')) {
          uniqueEmpSet.add('salma');
        } else if (un.contains('malak')) {
          uniqueEmpSet.add('malak');
        } else if (un.contains('dieved') || un.contains('devied')) {
          uniqueEmpSet.add('dieved');
        } else if (un.contains('abdelkreem')) {
          uniqueEmpSet.add('abdelkreem');
        } else if (un.isNotEmpty) {
          uniqueEmpSet.add(un);
        }
      }
    }
    uniqueEmpSet.addAll({'salma', 'malak', 'dieved', 'abdelkreem'});
    final int totalEmpCount = uniqueEmpSet.length;


    return Scaffold(
      key: _scaffoldKey,
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: currentUser?.username ?? 'مسؤول النظام'),

            // Dashboard content scroll
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Page title
                      Text('لوحة الإدارة', style: AppStyles.titleLarge),
                      Text(
                        'إدارة الموظفين، المهام، والمحتوى من مكان واحد',
                        style: AppStyles.bodyMuted,
                      ),
                      SizedBox(height: 16.h),

                      // Admin Order Approvals Banner
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.secondaryAccent, AppColors.primaryAccent]),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: AppStyles.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مراجعة طلبات العملاء والموافقات 📋',
                                    style: AppStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'معاينة صور إيصالات الدفع (InstaPay) والموافقة أو الرفض',
                                    style: AppStyles.bodyMuted.copyWith(color: Colors.white70, fontSize: 11.sp),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryAccent,
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: const Text('فتح الطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Total Employees Stat Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryAccent.withOpacity(0.16),
                              AppColors.secondaryAccent.withOpacity(0.14),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: AppStyles.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.people_alt_rounded, color: AppColors.primaryAccent, size: 28),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إجمالي عدد الموظفين',
                                    style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'سلمى • ملك • ديفيد • عبد الكريم${totalEmpCount > 4 ? " (+${totalEmpCount - 4} جديد)" : ""}',
                                    style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$totalEmpCount',
                              style: AppStyles.titleLarge.copyWith(fontSize: 26.sp, fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Quick Operations Card info
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3), width: 1.5),
                          borderRadius: AppStyles.cardRadius,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوحة العمليات السريعة',
                              style: AppStyles.titleSmall.copyWith(color: AppColors.primaryAccent),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'استخدم النموذج أدناه لإضافة موظف جديد وتخصيص صلاحياته.',
                              style: AppStyles.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Create User Card
                      _buildFormCard(
                        title: 'إضافة موظف جديد',
                        subtitle: 'أنشئ حسابات للموظفين الجدد',
                        icon: Icons.person_add_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('اسم المستخدم', style: AppStyles.labelBold),
                            SizedBox(height: 6.h),
                            TextField(
                              controller: _usernameController,
                              style: const TextStyle(color: AppColors.textMain),
                              decoration: const InputDecoration(hintText: 'اسم المستخدم للموظف'),
                            ),
                            SizedBox(height: 16.h),
                            _buildGradientButton(
                              text: '+ إنشاء موظف',
                              onPressed: userProvider.isLoading ? null : _createNewUser,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Users List Section
                      Text('قائمة الموظفين', style: AppStyles.titleMedium),
                      SizedBox(height: 12.h),
                      supervisorsOnly.isEmpty
                          ? _buildEmptyState(Icons.people_outline, 'لا توجد موظفون')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: supervisorsOnly.length,
                              itemBuilder: (context, idx) {
                                final u = supervisorsOnly[idx];
                                return _buildUserCard(u);
                              },
                            ),
                      SizedBox(height: 24.h),

                      // Payment Proof Screenshots Review Section (InstaPay & Vodafone Cash)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, color: AppColors.primaryAccent, size: 20.r),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text('إيصالات التحويل للمراجعة (InstaPay / Cash)', style: AppStyles.titleMedium, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '${_samplePaymentProofs.length} إيصالات',
                              style: TextStyle(color: AppColors.primaryAccent, fontSize: 10.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      _samplePaymentProofs.isEmpty
                          ? _buildEmptyState(Icons.receipt_long_outlined, 'لا توجد إيصالات تحويل جديدة للمراجعة')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _samplePaymentProofs.length,
                              itemBuilder: (context, idx) {
                                final proof = _samplePaymentProofs[idx];
                                return _buildPaymentProofCard(proof);
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
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: 'dashboard',
        isAdmin: true,
      ),
    );
  }

  // Component Builders
  Widget _buildStatCard(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryAccent.withOpacity(0.16),
              AppColors.secondaryAccent.withOpacity(0.14),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primaryAccent, size: 20),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryAccent),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp)),
                SizedBox(height: 4.h),
                Text(value, style: AppStyles.titleMedium.copyWith(fontSize: 18.sp)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: AppStyles.cardRadius,
        boxShadow: AppStyles.cardShadow,
      ),
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
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                    Text(subtitle, style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          child,
        ],
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
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
          padding: EdgeInsets.symmetric(vertical: 13.h),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppStyles.labelBold.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic u) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => copyToClipboard(context, u.username, label: 'اسم المستخدم'),
                  borderRadius: BorderRadius.circular(4.r),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(u.username, style: AppStyles.labelBold),
                      SizedBox(width: 4.w),
                      Icon(Icons.copy_rounded, size: 12.r, color: AppColors.primaryAccent),
                    ],
                  ),
                ),
                Text('ID: ${u.id}', style: AppStyles.bodyMuted),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailScreen(userId: u.id, username: u.username),
                    ),
                  );
                },
                child: const Text('عرض التفاصيل', style: TextStyle(color: AppColors.secondaryAccent, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.dangerStart),
                onPressed: () => _confirmDeleteUser(u.id, u.username),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic t) {
    final bool isCompleted = t.status == 'done';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border(
          right: BorderSide(color: AppColors.primaryAccent, width: 4),
          left: BorderSide(color: AppColors.borderLight),
          top: BorderSide(color: AppColors.borderLight),
          bottom: BorderSide(color: AppColors.borderLight),
        ),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: AppStyles.labelBold),
                Text(
                  '${t.description.isEmpty ? "بدون وصف" : t.description} | ${t.assignedToUsername ?? "غير محدد"}',
                  style: AppStyles.bodyMuted,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted ? AppColors.badgeDoneGradient : AppColors.warningGradient,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              isCompleted ? '✓ مكتملة' : '⏳ قيد الانتظار',
              style: AppStyles.labelBold.copyWith(fontSize: 10.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofCard(Map<String, dynamic> proof) {
    final bool isVerified = proof['is_verified'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isVerified ? AppColors.successStart : AppColors.borderLight,
          width: isVerified ? 1.5 : 1.0,
        ),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt, color: AppColors.primaryAccent, size: 20.r),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(proof['user_name'], style: AppStyles.labelBold.copyWith(fontSize: 14.sp), overflow: TextOverflow.ellipsis),
                          Text('${proof['id']} | ${proof['payment_method']}', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isVerified ? AppColors.successStart.withOpacity(0.12) : AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  isVerified ? 'تم التأكيد ✓' : proof['status_ar'],
                  style: TextStyle(
                    color: isVerified ? AppColors.successStart : AppColors.textMain,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المبلغ: ${proof['amount']}', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13.sp), overflow: TextOverflow.ellipsis),
                    Text('رقم المحول: ${proof['sender_phone']}', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full Image Proof Screenshot Viewer Button
                  ElevatedButton.icon(
                    onPressed: () => _showFullProofScreenshot(proof),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white),
                    label: const Text('عرض الإيصال', style: TextStyle(color: Colors.white, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Approve / Reject Button
                  if (!isVerified)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          proof['is_verified'] = true;
                          proof['status_ar'] = 'مقبول والمعاملة صحيحة ✓';
                        });
                        _showSnackbar('✓ تم اعتماد وإثبات دفع المعاملة ${proof['id']}', AppColors.successStart);
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.successStart),
                      tooltip: 'اعتماد الدفع',
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullProofScreenshot(Map<String, dynamic> proof) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إيصال التحويل: ${proof['id']}',
                    style: AppStyles.labelBold.copyWith(fontSize: 16.sp),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  height: 280.h,
                  width: double.infinity,
                  color: AppColors.inputBg,
                  child: InteractiveViewer(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, color: AppColors.primaryAccent, size: 64.r),
                          SizedBox(height: 12.h),
                          Text('صورة إيصال تحويل ${proof['payment_method']}', style: AppStyles.labelBold),
                          SizedBox(height: 4.h),
                          Text('المبلغ: ${proof['amount']} | رقم المحول: ${proof['sender_phone']}', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  minimumSize: Size(double.infinity, 44.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('إغلاق المعاينة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textMuted),
          SizedBox(height: 8.h),
          Text(message, style: AppStyles.bodyMuted),
        ],
      ),
    );
  }
}
