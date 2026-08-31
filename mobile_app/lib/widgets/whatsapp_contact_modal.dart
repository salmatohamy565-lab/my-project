import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class WhatsAppContactModal extends StatelessWidget {
  const WhatsAppContactModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WhatsAppContactModal(),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String rawPhone) async {
    final String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri phoneUri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (_) {}
  }

  Future<void> _launchWhatsApp(BuildContext context, String rawPhone) async {
    final String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final String formattedPhone = cleanPhone.startsWith('0') ? '2$cleanPhone' : cleanPhone;
    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent("أهلاً بك")}');

    try {
      final bool launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback try launchUrl without externalApplication mode
        final bool fallbackLaunched = await launchUrl(whatsappUri);
        if (!fallbackLaunched && context.mounted) {
          _showWhatsAppNotInstalledError(context);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showWhatsAppNotInstalledError(context);
      }
    }
  }

  void _showWhatsAppNotInstalledError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تطبيق واتساب غير مثبت على جهازك، يرجى تثبيت WhatsApp للتواصل المباشر.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.dangerStart,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle indicator
          Center(
            child: Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Modal Title Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.successStart.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: AppColors.successStart, size: 24),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تواصل معنا عبر واتساب',
                      style: AppStyles.titleMedium.copyWith(fontSize: 17.sp),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'اختر الرقم المناسب لبدء محادثة مباشرة مع خدمة العملاء',
                      style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 24),

          // Option 1: WhatsApp Number 1 (01001696249)
          _buildPhoneOptionCard(
            context,
            phoneNumber: '01001696249',
          ),
          SizedBox(height: 12.h),

          // Option 2: WhatsApp Number 2 (01228569626)
          _buildPhoneOptionCard(
            context,
            phoneNumber: '01228569626',
          ),
          SizedBox(height: 18.h),

          // Close button
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              side: const BorderSide(color: AppColors.borderMedium),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: Text(
              'إلغاء',
              style: AppStyles.labelBold.copyWith(color: AppColors.textDefault),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneOptionCard(
    BuildContext context, {
    String? title,
    required String phoneNumber,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _launchWhatsApp(context, phoneNumber);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.successStart,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.chat, color: Colors.white, size: 20),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(title, style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                    SizedBox(height: 2.h),
                  ],
                  Text(
                    phoneNumber,
                    style: AppStyles.labelBold.copyWith(fontSize: 16.sp, letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                _makePhoneCall(context, phoneNumber);
              },
              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green),
              tooltip: 'رنة على التليفون / اتصال مباشر',
            ),
            SizedBox(width: 4.w),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14.r),
          ],
        ),
      ),
    );
  }
}
