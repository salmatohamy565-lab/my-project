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
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_logo_bar.dart';

class EmployeeFilesScreen extends StatefulWidget {
  const EmployeeFilesScreen({super.key});

  @override
  State<EmployeeFilesScreen> createState() => _EmployeeFilesScreenState();
}

class _EmployeeFilesScreenState extends State<EmployeeFilesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDownloading = false;
  String? _downloadingFilename;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }

  Future<void> _loadFiles() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser != null) {
      await context.read<UserProvider>().fetchUserFiles(currentUser.id);
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
    final userProvider = context.watch<UserProvider>();
    
    final currentUser = authProvider.currentUser;
    final myFiles = userProvider.userFiles;

    return Scaffold(
      key: _scaffoldKey,
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: currentUser?.username ?? 'الموظف'),

            // Main Content Area
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFiles,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Page title
                      Text('ملفاتي', style: AppStyles.titleLarge),
                      Text(
                        'عرض وتحميل الملفات الخاصة بك',
                        style: AppStyles.bodyMuted,
                      ),
                      SizedBox(height: 24.h),

                      // Container Card
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
                                  child: const Icon(Icons.folder_open_outlined, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الملفات الخاصة بالعمل', style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                                    Text('كل ما رفعته أو أرسل إليك يمكنك تنزيله من هنا', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.borderLight, height: 32),

                            if (userProvider.isLoading && myFiles.isEmpty)
                              const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                            else if (myFiles.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.h),
                                child: Column(
                                  children: [
                                    Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                                    SizedBox(height: 12.h),
                                    Text('لا توجد ملفات بعد في حسابك', style: AppStyles.bodyMuted),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: myFiles.length,
                                itemBuilder: (context, index) {
                                  final file = myFiles[index];
                                  final isThisDownloading = _isDownloading && _downloadingFilename == file.filename;

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
                                              Text(
                                                file.filename,
                                                style: AppStyles.labelBold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                'مرفوع بواسطة: ${file.uploadedBy} • ${file.uploadedAt ?? ""}',
                                                style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
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
                                              : Text('تنزيل', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
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
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: 'files',
        isAdmin: false,
      ),
    );
  }
}
