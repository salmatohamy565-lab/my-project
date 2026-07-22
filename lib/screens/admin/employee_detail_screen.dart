import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
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

class EmployeeDetailScreen extends StatefulWidget {
  final int userId;
  final String username;

  const EmployeeDetailScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  bool _isDownloading = false;
  String? _downloadingFilename;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<UserProvider>().fetchUserFiles(widget.userId),
      context.read<UserProvider>().fetchUserAttendance(widget.userId),
      context.read<TaskProvider>().fetchTasks(),
    ]);
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
    final userProvider = context.watch<UserProvider>();
    final taskProvider = context.watch<TaskProvider>();

    final userFiles = userProvider.userFiles;
    final userAttendance = userProvider.userAttendance;
    final userTasks = taskProvider.tasks.where((t) => t.assignedTo == widget.userId).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.globalLogoBarBg,
        title: Text(widget.username, style: AppStyles.titleSmall),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RadialBackground(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: AppStyles.cardRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.username, style: AppStyles.titleLarge),
                      SizedBox(height: 4.h),
                      Text('صفحة تفصيلية خاصة بالموظف (ID: ${widget.userId})', style: AppStyles.bodyMuted),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Mini Stats Grid
                Row(
                  children: [
                    Expanded(child: _buildMiniStatCard('المهام', '${userTasks.length}')),
                    SizedBox(width: 10.w),
                    Expanded(child: _buildMiniStatCard('الملفات', '${userFiles.length}')),
                    SizedBox(width: 10.w),
                    Expanded(child: _buildMiniStatCard('السجل', '${userAttendance.length}')),
                  ],
                ),
                SizedBox(height: 24.h),

                // Tasks List Card
                _buildSectionCard(
                  title: 'المهام الموكلة',
                  icon: Icons.assignment_outlined,
                  child: userTasks.isEmpty
                      ? _buildEmptyState('لا توجد مهام موكلة حالياً')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userTasks.length,
                          itemBuilder: (context, index) {
                            final task = userTasks[index];
                            final isDone = task.status == 'done';
                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
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
                                        Text(
                                          task.description.isEmpty ? 'بدون وصف' : task.description,
                                          style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDone ? AppColors.badgeDoneGradient : AppColors.warningGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      isDone ? '✓ مكتملة' : '⏳ قيد الانتظار',
                                      style: AppStyles.labelBold.copyWith(fontSize: 9.sp, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 20.h),

                // Files List Card
                _buildSectionCard(
                  title: 'الملفات المرفوعة',
                  icon: Icons.folder_open_outlined,
                  child: userFiles.isEmpty
                      ? _buildEmptyState('لا توجد ملفات مرفوعة')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userFiles.length,
                          itemBuilder: (context, index) {
                            final file = userFiles[index];
                            final isThisDownloading = _isDownloading && _downloadingFilename == file.filename;

                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                                        Text(file.filename, style: AppStyles.labelBold, overflow: TextOverflow.ellipsis),
                                        Text('بواسطة: ${file.uploadedBy}', style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: isThisDownloading
                                        ? null
                                        : () => _downloadAndOpenFile(file.url, file.filename),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryAccent.withOpacity(0.14),
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                    ),
                                    child: isThisDownloading
                                        ? SizedBox(
                                            height: 14.w,
                                            width: 14.w,
                                            child: const CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                          )
                                        : Text('تحميل', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 20.h),

                // Attendance Section
                _buildSectionCard(
                  title: 'سجل الحضور والغياب',
                  icon: Icons.calendar_month_outlined,
                  child: userAttendance.isEmpty
                      ? _buildEmptyState('لا يوجد سجل حضور وغياب')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userAttendance.length,
                          itemBuilder: (context, index) {
                            final att = userAttendance[index];
                            final isPresent = att.status == 'present';
                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(att.attendanceDate, style: AppStyles.labelBold),
                                      if (att.checkInTime != null || att.checkOutTime != null)
                                        Text(
                                          'توقيت: ${att.checkInTime ?? "-"} إلى ${att.checkOutTime ?? "-"}',
                                          style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isPresent ? AppColors.successGradient : AppColors.dangerGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      isPresent ? 'حضور' : 'غياب',
                                      style: AppStyles.labelBold.copyWith(fontSize: 10.sp, color: Colors.white),
                                    ),
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
    );
  }

  Widget _buildMiniStatCard(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          Text(label, style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
          SizedBox(height: 4.h),
          Text(value, style: AppStyles.titleMedium.copyWith(fontSize: 18.sp)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
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
              Icon(icon, color: AppColors.primaryAccent, size: 20),
              SizedBox(width: 10.w),
              Text(title, style: AppStyles.titleSmall),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Text(
        msg,
        style: AppStyles.bodyMuted,
        textAlign: TextAlign.center,
      ),
    );
  }
}
