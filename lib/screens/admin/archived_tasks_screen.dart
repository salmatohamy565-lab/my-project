import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/admin_drawer.dart';

class ArchivedTasksScreen extends StatefulWidget {
  const ArchivedTasksScreen({super.key});

  @override
  State<ArchivedTasksScreen> createState() => _ArchivedTasksScreenState();
}

class _ArchivedTasksScreenState extends State<ArchivedTasksScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchArchivedTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    
    final currentUser = authProvider.currentUser;
    final archivedTasks = taskProvider.archivedTasks;

    return Scaffold(
      key: _scaffoldKey,
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(
              trailing: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(currentUser?.username ?? 'مسؤول النظام', style: AppStyles.labelBold),
                  SizedBox(width: 8.w),
                  CircleAvatar(
                    radius: 16.r,
                    backgroundColor: AppColors.primaryAccent.withOpacity(0.08),
                    child: const Icon(Icons.person, color: AppColors.primaryAccent, size: 20),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<TaskProvider>().fetchArchivedTasks(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header title
                      Text('المهام المؤرشفة', style: AppStyles.titleLarge),
                      Text(
                        'عرض المهام المكتملة والمنتقلة للأرشيف',
                        style: AppStyles.bodyMuted,
                      ),
                      SizedBox(height: 24.h),

                      // List Container Card
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
                                  child: const Icon(Icons.archive_outlined, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('قائمة المهام المؤرشفة', style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                                      Text('المهام المكتملة التي تم أرشفتها تلقائياً', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.borderLight, height: 32),

                            if (taskProvider.isLoading && archivedTasks.isEmpty)
                              const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                            else if (archivedTasks.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.h),
                                child: Column(
                                  children: [
                                    Icon(Icons.archive_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                                    SizedBox(height: 12.h),
                                    Text('لا توجد مهام مؤرشفة بعد', style: AppStyles.bodyMuted),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: archivedTasks.length,
                                itemBuilder: (context, index) {
                                  final task = archivedTasks[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    padding: EdgeInsets.all(14.w),
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
                                                '${task.description.isEmpty ? "بدون وصف" : task.description} | ${task.assignedToUsername ?? "غير محدد"}',
                                                style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: AppColors.badgeDoneGradient,
                                            ),
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: Text(
                                            '✓ مؤرشف',
                                            style: AppStyles.labelBold.copyWith(fontSize: 10.sp, color: Colors.white),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
