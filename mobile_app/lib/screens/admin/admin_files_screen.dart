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
import '../../services/api_service.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_logo_bar.dart';

class AdminFilesScreen extends StatefulWidget {
  const AdminFilesScreen({super.key});

  @override
  State<AdminFilesScreen> createState() => _AdminFilesScreenState();
}

class _AdminFilesScreenState extends State<AdminFilesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  int? _selectedUserId;
  File? _selectedFile;
  bool _isDownloading = false;
  String? _downloadingFilename;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
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
    if (_selectedUserId == null) {
      _showSnackbar('يرجى اختيار الموظف أولاً', Colors.red);
      return;
    }
    if (_selectedFile == null) {
      _showSnackbar('يرجى اختيار ملف للرفع', Colors.red);
      return;
    }

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.uploadUserFile(_selectedUserId!, _selectedFile!);
    
    if (success) {
      _showSnackbar('✓ تم رفع الملف بنجاح', AppColors.successStart);
      setState(() {
        _selectedFile = null;
      });
      // Refresh user files
      await userProvider.fetchUserFiles(_selectedUserId!);
    } else {
      final error = userProvider.errorMessage ?? 'فشل رفع الملف';
      _showSnackbar(error, Colors.red);
    }
  }

  Future<void> _toggleArchive(String filename) async {
    if (_selectedUserId == null) return;
    
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.toggleFileArchive(_selectedUserId!, filename, true);
    
    if (success) {
      _showSnackbar('تم أرشفة الملف بنجاح', AppColors.primaryAccent);
    } else {
      final error = userProvider.errorMessage ?? 'فشل أرشفة الملف';
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
      
      // Download the file passing cookies for auth
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

      // Open the downloaded file using open_filex
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
    final staffList = userProvider.users;
    final employeeFiles = userProvider.userFiles;

    final supervisorsOnly = staffList.where((u) => u.role != 'admin').toList();

    return Scaffold(
      key: _scaffoldKey,
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: currentUser?.username ?? 'مسؤول النظام'),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Page Title
                    Text('إدارة الملفات', style: AppStyles.titleLarge),
                    Text(
                      'رفع الملفات للموظفين من صفحة موحدة ومريحة',
                      style: AppStyles.bodyMuted,
                    ),
                    SizedBox(height: 24.h),

                    // File upload form card
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: AppStyles.cardRadius,
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: Form(
                        key: _formKey,
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
                                  child: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('رفع الملفات للموظفين', style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                                      Text('اختر موظفًا ثم ارفع الملف', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),

                            // Employee dropdown
                            Text('الموظف', style: AppStyles.labelBold),
                            SizedBox(height: 8.h),
                            DropdownButtonFormField<int>(
                              dropdownColor: AppColors.loginCardBg,
                              value: _selectedUserId,
                              style: const TextStyle(color: AppColors.textMain),
                              decoration: const InputDecoration(
                                hintText: '-- اختر موظف --',
                              ),
                              items: supervisorsOnly.map((u) {
                                return DropdownMenuItem<int>(
                                  value: u.id,
                                  child: Text(u.username),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedUserId = val;
                                  _selectedFile = null;
                                });
                                if (val != null) {
                                  userProvider.fetchUserFiles(val);
                                }
                              },
                            ),
                            SizedBox(height: 20.h),

                            // File selection
                            Text('الملف المطلوب رفعه', style: AppStyles.labelBold),
                            SizedBox(height: 8.h),
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
                                            : 'اختر ملفاً للرفع',
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
                            SizedBox(height: 24.h),

                            // Submit Button
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
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  alignment: Alignment.center,
                                  child: userProvider.isLoading
                                      ? SizedBox(
                                          height: 20.w,
                                          width: 20.w,
                                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          'رفع الملف للموظف',
                                          style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 15.sp),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Employee current files card
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
                                child: const Icon(Icons.folder_outlined, color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ملفات الموظف الحالي', style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                                    Text('عرض الملفات الحالية مع أدوات الأرشفة', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),

                          if (_selectedUserId == null)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Text(
                                'اختر موظفًا لعرض ملفاته.',
                                style: AppStyles.bodyMuted,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (userProvider.isLoading && employeeFiles.isEmpty)
                            const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                          else if (employeeFiles.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Text(
                                'لا توجد ملفات لهذا الموظف حالياً.',
                                style: AppStyles.bodyMuted,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: employeeFiles.length,
                              itemBuilder: (context, index) {
                                final file = employeeFiles[index];
                                final isThisDownloading = _isDownloading && _downloadingFilename == file.filename;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
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
                                              '${file.uploadedBy} • ${file.uploadedAt ?? ""}',
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
                                            onPressed: () => _toggleArchive(file.filename),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white.withOpacity(0.08),
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                              side: BorderSide(color: Colors.white.withOpacity(0.18)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                            ),
                                            child: Text('أرشفة', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
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
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentRoute: 'files',
        isAdmin: true,
      ),
    );
  }
}
