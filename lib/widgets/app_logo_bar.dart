import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/auth_provider.dart';
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo image (wrapped to prevent overflow)
          Flexible(
            child: SvgPicture.asset(
              'assets/logo2.svg',
              height: 40.h,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),
          SizedBox(width: 8.w),
          // Trailing content
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
                  IconButton(
                    icon: Icon(Icons.notifications_active_outlined, color: AppColors.primaryAccent, size: 24.r),
                    onPressed: () => NotificationsModal.show(context),
                    tooltip: 'الإشعارات',
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
