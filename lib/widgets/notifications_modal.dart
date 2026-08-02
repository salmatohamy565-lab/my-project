import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationsModal extends StatefulWidget {
  const NotificationsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsModal(),
    );
  }

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await _apiService.getNotifications();
      if (mounted) {
        final list = (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
        // Mark as read after fetching
        _apiService.markNotificationsRead();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_active_rounded, color: AppColors.primaryAccent, size: 22.r),
                  ),
                  SizedBox(width: 10.w),
                  Text('الإشعارات والرسائل', style: AppStyles.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 20),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 54.sp, color: AppColors.textMuted),
                            SizedBox(height: 12.h),
                            Text('لا توجد إشعارات جديدة حالياً', style: AppStyles.bodyMuted),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (ctx, idx) {
                          final notif = _notifications[idx];
                          final isAccept = notif.message.contains('تمت الموافقة');
                          final isReject = notif.message.contains('تم رفض');

                          return Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: isAccept
                                  ? AppColors.emeraldGreen.withOpacity(0.06)
                                  : isReject
                                      ? AppColors.dangerStart.withOpacity(0.06)
                                      : AppColors.inputBg,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isAccept
                                    ? AppColors.emeraldGreen.withOpacity(0.3)
                                    : isReject
                                        ? AppColors.dangerStart.withOpacity(0.3)
                                        : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: isAccept
                                      ? AppColors.emeraldGreen.withOpacity(0.15)
                                      : isReject
                                          ? AppColors.dangerStart.withOpacity(0.15)
                                          : AppColors.primaryAccent.withOpacity(0.15),
                                  child: Icon(
                                    isAccept
                                        ? Icons.check_circle_rounded
                                        : isReject
                                            ? Icons.cancel_rounded
                                            : Icons.info_rounded,
                                    color: isAccept
                                        ? AppColors.emeraldGreen
                                        : isReject
                                            ? AppColors.dangerStart
                                            : AppColors.primaryAccent,
                                    size: 20.r,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: AppStyles.labelBold.copyWith(fontSize: 14.sp),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        notif.message,
                                        style: AppStyles.bodyDefault.copyWith(fontSize: 12.sp),
                                      ),
                                      if (notif.createdAt != null) ...[
                                        SizedBox(height: 6.h),
                                        Text(
                                          '${notif.createdAt!.hour}:${notif.createdAt!.minute.toString().padLeft(2, '0')}',
                                          style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp),
                                        ),
                                      ],
                                    ],
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
    );
  }
}
