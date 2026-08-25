import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notifications_modal.dart';

import '../utils/copy_utils.dart';

/// Unified top bar used across all app screens.
/// Shows the Bola Designs logo on the left and optional trailing widget on the right.
class AppLogoBar extends StatelessWidget {
  final String? username;
  final Widget? trailing;

  const AppLogoBar({
    super.key,
    this.username,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final String logoAsset = 'assets/logo.svg';
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 0),
      height: 56.h,
      decoration: const BoxDecoration(
        color: AppColors.globalLogoBarBg,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand / Logo section
          Flexible(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    'assets/bola_logo.png',
                    height: 36.h,
                    width: 36.h,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/LOGO_new_bola_designs_for_dark_cx.png',
                        height: 36.h,
                        width: 36.h,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'BOLA DESIGNS',
                    style: AppStyles.titleMedium.copyWith(
                      color: AppColors.primaryAccent,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // User / Actions section
          if (trailing != null)
            Flexible(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: trailing!,
                ),
              ),
            )
          else if (username != null)
            Flexible(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, child) {
                      final unreadCount = notifProvider.unreadCount;
                      final badgeText = unreadCount > 9 ? '9+' : unreadCount.toString();

                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications_active_outlined, color: AppColors.primaryAccent, size: 24.r),
                            onPressed: () {
                              NotificationsModal.show(context);
                              notifProvider.markAllAsRead();
                            },
                            tooltip: 'الإشعارات',
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 4.h,
                              right: 4.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10.r),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16.w,
                                  minHeight: 16.h,
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: InkWell(
                      onTap: () => copyToClipboard(context, username!, label: 'اسم المستخدم'),
                      borderRadius: BorderRadius.circular(6.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        child: Text(
                          username!,
                          style: AppStyles.labelBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  InkWell(
                    onTap: () => copyToClipboard(context, username!, label: 'اسم المستخدم'),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Builder(
                      builder: (context) {
                        final avatarImage = currentUser?.getProfileImageProvider(authProvider.baseUrl);
                        return CircleAvatar(
                          radius: 16.r,
                          backgroundColor: AppColors.primaryAccent.withOpacity(0.08),
                          backgroundImage: avatarImage,
                          onBackgroundImageError: avatarImage != null ? (_, __) {} : null,
                          child: avatarImage == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primaryAccent,
                                  size: 20,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
