import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/app_logo_bar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedUserId;
  DateTime _selectedDate = DateTime.now();
  String _status = 'present'; // default to present

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar', ''),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryAccent,
              onPrimary: Colors.black,
              surface: AppColors.loginCardBg,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.bgEnd,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedUserId == null) {
      _showSnackbar('يرجى اختيار الموظف أولاً', Colors.red);
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final userProvider = context.read<UserProvider>();

    final success = await userProvider.saveAttendance(
      _selectedUserId!,
      formattedDate,
      _status,
    );

    if (success) {
      _showSnackbar('✓ تم حفظ حالة الحضور/الغياب بنجاح', AppColors.successStart);
      setState(() {
        _selectedUserId = null;
        _selectedDate = DateTime.now();
        _status = 'present';
      });
    } else {
      final error = userProvider.errorMessage ?? 'فشل حفظ الحالة';
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
    final staffList = userProvider.users;

    final supervisorsOnly = staffList.where((u) => u.role != 'admin').toList();
    final formattedDateText = DateFormat('yyyy-MM-dd').format(_selectedDate);

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
                    // Page title
                    Text('الحضور والغياب', style: AppStyles.titleLarge),
                    Text(
                      'تسجيل حضور أو غياب أي موظف بدقة',
                      style: AppStyles.bodyMuted,
                    ),
                    SizedBox(height: 24.h),

                    // Registration Card Form
                    Container(
                      padding: EdgeInsets.all(24.w),
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
                                  child: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('سجل اليوم', style: AppStyles.titleSmall.copyWith(fontSize: 14.sp)),
                                      Text('سجل حضور أو غياب أي موظف من هنا', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),

                            // Employee Dropdown
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
                                });
                              },
                            ),
                            SizedBox(height: 20.h),

                            // Date picker
                            Text('التاريخ', style: AppStyles.labelBold),
                            SizedBox(height: 8.h),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBg,
                                  border: Border.all(color: AppColors.borderDark),
                                  borderRadius: AppStyles.inputRadius,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formattedDateText,
                                      style: AppStyles.bodyDefault.copyWith(color: AppColors.textMain),
                                    ),
                                    const Icon(Icons.calendar_today, color: AppColors.primaryAccent),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // Status dropdown
                            Text('الحالة', style: AppStyles.labelBold),
                            SizedBox(height: 8.h),
                            DropdownButtonFormField<String>(
                              dropdownColor: AppColors.loginCardBg,
                              value: _status,
                              style: const TextStyle(color: AppColors.textMain),
                              decoration: const InputDecoration(),
                              items: const [
                                DropdownMenuItem(value: 'present', child: Text('حضور')),
                                DropdownMenuItem(value: 'absent', child: Text('غياب')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _status = val;
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 28.h),

                            // Submit Button
                            ElevatedButton(
                              onPressed: userProvider.isLoading ? null : _saveAttendance,
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
                                          'حفظ الحالة',
                                          style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 15.sp),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
        currentRoute: 'attendance',
        isAdmin: true,
      ),
    );
  }
}
