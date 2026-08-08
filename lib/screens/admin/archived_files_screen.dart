import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/admin_drawer.dart';

class ArchivedFilesScreen extends StatefulWidget {
  const ArchivedFilesScreen({super.key});

  @override
  State<ArchivedFilesScreen> createState() => _ArchivedFilesScreenState();
}

class _ArchivedFilesScreenState extends State<ArchivedFilesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDownloading = false;
  String? _downloadingFilename;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchArchivedFiles();
    });
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

  Future<void> _restoreFile(int userId, String filename) async {
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.toggleFileArchive(userId, filename, false);
    if (success) {
      _showSnackbar('تم إلغاء أرشفة الملف بنجاح', AppColors.successStart);
      await userProvider.fetchArchivedFiles();
    } else {
      final error = userProvider.errorMessage ?? 'فشل إلغاء الأرشفة';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    final userProvider = context.read<UserProvider>();
    final csvContent = await userProvider.exportArchivedFilesCsv();

    setState(() {
      _isExporting = false;
    });

    if (csvContent != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/archived_files.csv';
        final file = File(savePath);
        await file.writeAsString(csvContent);

        _showSnackbar('تم تصدير ملف CSV بنجاح', AppColors.successStart);
        
        // Open the CSV file
        await OpenFilex.open(savePath);
      } catch (e) {
        _showSnackbar('فشل حفظ ملف CSV المصدر', Colors.red);
      }
    } else {
      final error = userProvider.errorMessage ?? 'فشل تصدير CSV';
      _showSnackbar(error, Colors.red);
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
    final archivedFiles = userProvider.archivedFiles;

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

            // Scrollable content area
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<UserProvider>().fetchArchivedFiles(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Page title
                      Text('الملفات المؤرشفة', style: AppStyles.titleLarge),
                      Text(
                        'عرض وتنزيل الملفات التي تم أرشفتها',
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        Text('الملفات المؤرشفة', style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                                        Text('الملفات المؤرشفة يدوياً أو آلياً', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isExporting ? null : _exportCsv,
                                  icon: _isExporting
                                      ? SizedBox(
                                          height: 14.w,
                                          width: 14.w,
                                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                                        )
                                      : const Icon(Icons.download, size: 16, color: Colors.white),
                                  label: Text(
                                    'تصدير CSV',
                                    style: AppStyles.labelBold.copyWith(fontSize: 11.sp, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryAccent,
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.borderLight, height: 32),

                            if (userProvider.isLoading && archivedFiles.isEmpty)
                              const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                            else if (archivedFiles.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.h),
                                child: Column(
                                  children: [
                                    Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                                    SizedBox(height: 12.h),
                                    Text('لا توجد ملفات مؤرشفة', style: AppStyles.bodyMuted),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: archivedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = archivedFiles[index];
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
                                                'بواسطة: ${file.uploadedBy} • ${file.uploadedAt ?? ""}',
                                                style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: isThisDownloading
                                                  ? null
                                                  : () => _downloadAndOpenFile(file.url, file.filename),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primaryAccent.withOpacity(0.14),
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
                                            SizedBox(width: 8.w),
                                            ElevatedButton(
                                              onPressed: () => _restoreFile(file.userId ?? 0, file.filename),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white.withOpacity(0.08),
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                                side: BorderSide(color: Colors.white.withOpacity(0.18)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                              ),
                                              child: Text('إلغاء الأرشفة', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
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
