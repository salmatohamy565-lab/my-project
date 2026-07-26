import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_logo_bar.dart';
import '../products/products_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  File? _selectedFile;
  Timer? _refreshTimer;
  bool _isDownloading = false;
  String? _downloadingFilename;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // Start periodic refresh every 5 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _loadData();
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    await Future.wait([
      context.read<TaskProvider>().fetchTasks(),
      context.read<UserProvider>().fetchUserFiles(currentUser.id),
      context.read<UserProvider>().fetchUserAttendance(currentUser.id),
    ]);
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadFile() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    if (_selectedFile == null) {
      _showSnackbar('يرجى اختيار ملف أولاً', Colors.red);
      return;
    }

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.uploadUserFile(currentUser.id, _selectedFile!);

    if (success) {
      setState(() {
        _selectedFile = null;
      });
      _showSnackbar('✓ تم رفع الملف بنجاح', AppColors.successStart);
      _loadData();
    } else {
      final error = userProvider.errorMessage ?? 'فشل رفع الملف';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _markTaskDone(int taskId) async {
    final success = await context.read<TaskProvider>().markTaskDone(taskId);
    if (success) {
      _showSnackbar('تم إكمال المهمة بنجاح', AppColors.successStart);
      _loadData();
    } else {
      final error = context.read<TaskProvider>().errorMessage ?? 'فشل تحديث حالة المهمة';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _downloadAndOpenFile(String fileUrl, String filename) async {
    setState(() {
      _isDownloading = true;
      _downloadingFilename = filename;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$filename';
      
      final apiService = ApiService();
      final dio = Dio();
      
      await dio.download(
        '${apiService.baseUrl}$fileUrl',
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
        _showSnackbar('لا يمكن فتح هذا النوع من الملفات: ${result.message}', Colors.amber);
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadingFilename = null;
      });
      _showSnackbar('حدث خطأ أثناء تحميل وفتح الملف', Colors.red);
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
    final taskProvider = context.watch<TaskProvider>();
    final userProvider = context.watch<UserProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser != null && currentUser.isCustomer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ProductsScreen()),
          );
        }
      });
    }

    final myTasks = taskProvider.tasks;
    final myFiles = userProvider.userFiles;
    final myAttendance = userProvider.userAttendance;

    // Filter file types
    final managerFiles = myFiles.where((f) => f.uploadedByRole == 'admin').toList();
    final completedFiles = myFiles.where((f) => f.uploadedById == currentUser?.id).toList();

    return Scaffold(
      key: _scaffoldKey,
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: currentUser?.username ?? 'الموظف'),

            // Dashboard content scroll
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Page title
                      Text('لوحة الموظف', style: AppStyles.titleLarge),
                      Text(
                        'تابع مهامك، أرفع الملفات، وراجع مستنداتك',
                        style: AppStyles.bodyMuted,
                      ),
                      SizedBox(height: 20.h),

                      // Tasks Section
                      Container(
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
                                  child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('مهامي', style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                                    Text('المهام المسندة إليّ حالياً', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.borderLight, height: 32),

                            // List tasks
                            if (taskProvider.isLoading && myTasks.isEmpty)
                              const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                            else if (myTasks.isEmpty)
                              _buildEmptyState(Icons.assignment_turned_in, 'لا توجد مهام مسندة إليك')
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: myTasks.length,
                                itemBuilder: (context, index) {
                                  final task = myTasks[index];
                                  final isCompleted = task.status == 'done';

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.02),
                                      border: Border.all(color: AppColors.borderLight),
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(task.title, style: AppStyles.labelBold),
                                              SizedBox(height: 4.h),
                                              Text(
                                                task.description.isEmpty ? 'بدون وصف' : task.description,
                                                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Row(
                                          children: [
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
                                            if (!isCompleted) ...[
                                              SizedBox(width: 10.w),
                                              ElevatedButton(
                                                onPressed: () => _markTaskDone(task.id),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.successStart,
                                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                                ),
                                                child: Text(
                                                  'إكمال',
                                                  style: AppStyles.labelBold.copyWith(fontSize: 11.sp, color: Colors.white),
                                                ),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                            // File Upload Form
                            const Divider(color: AppColors.borderLight, height: 32),
                            Text('رفع ملف عملي', style: AppStyles.labelBold),
                            SizedBox(height: 8.h),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InkWell(
                                    onTap: _selectFile,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputBg,
                                        border: Border.all(color: AppColors.borderDark),
                                        borderRadius: AppStyles.inputRadius,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.attachment, color: AppColors.textMuted),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Text(
                                              _selectedFile != null
                                                  ? _selectedFile!.path.split(Platform.pathSeparator).last
                                                  : 'اختر ملف عمل للرفع',
                                              style: AppStyles.bodyDefault.copyWith(
                                                color: _selectedFile != null ? Colors.white : AppColors.textMuted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 14.h),
                                  ElevatedButton(
                                    onPressed: userProvider.isLoading ? null : _uploadFile,
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
                                        child: userProvider.isLoading
                                            ? SizedBox(
                                                height: 18.w,
                                                width: 18.w,
                                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : Text(
                                                'رفع الملف الآن',
                                                style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 14.sp),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Collapsible My Files Section
                            SizedBox(height: 20.h),
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  border: Border.all(color: AppColors.borderLight),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  title: Text(
                                    'ملفاتي المرفوعة سابقاً',
                                    style: AppStyles.labelBold,
                                  ),
                                  childrenPadding: EdgeInsets.all(12.w),
                                  children: [
                                    if (myFiles.isEmpty)
                                      Text('لا توجد ملفات بعد', style: AppStyles.bodyMuted)
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: myFiles.length,
                                        itemBuilder: (context, index) {
                                          final f = myFiles[index];
                                          final isThisDownloading = _isDownloading && _downloadingFilename == f.filename;

                                          return Padding(
                                            padding: EdgeInsets.only(bottom: 8.h),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    f.filename,
                                                    style: AppStyles.bodyDefault,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: isThisDownloading
                                                      ? null
                                                      : () => _downloadAndOpenFile(f.url, f.filename),
                                                  child: isThisDownloading
                                                      ? SizedBox(
                                                          height: 12.w,
                                                          width: 12.w,
                                                          child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryAccent),
                                                        )
                                                      : const Text('تحميل', style: TextStyle(color: AppColors.primaryAccent)),
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
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Quick Grids (Manager Files, Attendance Log, Completed Uploads)
                      Text('نظرة سريعة', style: AppStyles.titleMedium),
                      SizedBox(height: 12.h),
                      
                      // Manager Files
                      _buildQuickSummaryCard(
                        title: 'ملفات المدير',
                        icon: Icons.folder_shared_outlined,
                        child: managerFiles.isEmpty
                            ? Text('لا توجد ملفات من المدير حالياً', style: AppStyles.bodyMuted)
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: managerFiles.length,
                                itemBuilder: (context, index) {
                                  final f = managerFiles[index];
                                  final isThisDownloading = _isDownloading && _downloadingFilename == f.filename;

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            f.filename,
                                            style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: isThisDownloading
                                              ? null
                                              : () => _downloadAndOpenFile(f.url, f.filename),
                                          child: isThisDownloading
                                              ? SizedBox(
                                                  height: 12.w,
                                                  width: 12.w,
                                                  child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryAccent),
                                                )
                                              : Text('تنزيل', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent, fontSize: 12.sp)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 16.h),

                      // Attendance Log
                      _buildQuickSummaryCard(
                        title: 'أيام الحضور (آخر 7 أيام)',
                        icon: Icons.calendar_month_outlined,
                        child: myAttendance.isEmpty
                            ? Text('لا توجد سجل حضور بعد', style: AppStyles.bodyMuted)
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: myAttendance.length > 7 ? 7 : myAttendance.length,
                                itemBuilder: (context, index) {
                                  final att = myAttendance[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 6.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(att.attendanceDate, style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp)),
                                        Text(
                                          '${att.checkInTime ?? "-"} إلى ${att.checkOutTime ?? "-"}',
                                          style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 16.h),

                      // Completed Uploads
                      _buildQuickSummaryCard(
                        title: 'الملفات المكتملة',
                        icon: Icons.check_circle_outline,
                        child: completedFiles.isEmpty
                            ? Text('لا توجد ملفات مكتملة بعد', style: AppStyles.bodyMuted)
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: completedFiles.length,
                                itemBuilder: (context, index) {
                                  final f = completedFiles[index];
                                  final isThisDownloading = _isDownloading && _downloadingFilename == f.filename;

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            f.filename,
                                            style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: isThisDownloading
                                              ? null
                                              : () => _downloadAndOpenFile(f.url, f.filename),
                                          child: isThisDownloading
                                              ? SizedBox(
                                                  height: 12.w,
                                                  width: 12.w,
                                                  child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryAccent),
                                                )
                                              : Text('تنزيل', style: AppStyles.labelBold.copyWith(color: AppColors.primaryAccent, fontSize: 12.sp)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
        isAdmin: false,
      ),
    );
  }

  Widget _buildQuickSummaryCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryAccent, size: 18),
              SizedBox(width: 8.w),
              Text(title, style: AppStyles.labelBold.copyWith(fontSize: 13.sp)),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textMuted.withOpacity(0.5)),
          SizedBox(height: 8.h),
          Text(message, style: AppStyles.bodyMuted),
        ],
      ),
    );
  }
}
