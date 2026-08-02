import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/web_file_picker.dart';

class PaymentMethodsModal extends StatefulWidget {
  final String? productName;
  final double? productPrice;
  final Function? onConfirmOrder;

  const PaymentMethodsModal({
    super.key,
    this.productName,
    this.productPrice,
    this.onConfirmOrder,
  });

  static void show(
    BuildContext context, {
    String? productName,
    double? productPrice,
    Function? onConfirmOrder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentMethodsModal(
        productName: productName,
        productPrice: productPrice,
        onConfirmOrder: onConfirmOrder,
      ),
    );
  }

  @override
  State<PaymentMethodsModal> createState() => _PaymentMethodsModalState();
}

class _PaymentMethodsModalState extends State<PaymentMethodsModal> {
  String _selectedMethod = 'vodafone_cash';
  final TextEditingController _senderInfoController = TextEditingController();
  File? _proofFile;
  Uint8List? _proofBytes;
  String? _proofFileName;

  final String _vodafoneCashNumber = '01001696249';
  final String _instapayNumber = '01228569626';

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ تم نسخ رقم $label: $text', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.successStart,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickProofImage() async {
    try {
      final picked = await pickImageFile();

      if (picked != null) {
        if (picked.bytes != null && picked.bytes!.length > 5 * 1024 * 1024) {
          _showError('عفواً، الحد الأقصى لحجم صورة الإيصال هو 5 ميجابايت');
          return;
        }

        setState(() {
          _proofBytes = picked.bytes;
          _proofFileName = picked.name;
          _proofFile = picked.file;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ تم إرفاق صورة إيصال التحويل بنجاح!'),
              backgroundColor: AppColors.emeraldGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showError('حدث خطأ أثناء اختيار ملف الصورة: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.dangerStart,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _senderInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOrderMode = widget.productName != null && widget.productPrice != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.loginCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: AppStyles.cardShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header Title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOrderMode ? 'الدفع وإتمام الطلب' : 'طرق الدفع المتاحة',
                        style: AppStyles.titleMedium.copyWith(fontSize: 18.sp),
                      ),
                      Text(
                        isOrderMode ? 'اختر طريقة الدفع المناسبة لتحويل المبلغ' : 'بيانات حسابات التحويل والدفع الرسمية',
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

            // Order Summary Box (If order mode)
            if (isOrderMode) ...[
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المنتج المختار', style: AppStyles.bodyMuted.copyWith(fontSize: 10.sp)),
                          SizedBox(height: 2.h),
                          Text(widget.productName!, style: AppStyles.labelBold.copyWith(fontSize: 14.sp)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${widget.productPrice!.toStringAsFixed(2)} ج.م',
                        style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            Text('اختر طريقة الدفع للتحويل:', style: AppStyles.labelBold.copyWith(fontSize: 13.sp)),
            SizedBox(height: 10.h),

            // 1. Vodafone Cash Card
            InkWell(
              onTap: () => setState(() => _selectedMethod = 'vodafone_cash'),
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _selectedMethod == 'vodafone_cash' ? AppColors.primaryAccent.withOpacity(0.08) : AppColors.cardBg,
                  border: Border.all(
                    color: _selectedMethod == 'vodafone_cash' ? AppColors.primaryAccent : AppColors.borderLight,
                    width: _selectedMethod == 'vodafone_cash' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: 'vodafone_cash',
                          groupValue: _selectedMethod,
                          activeColor: AppColors.primaryAccent,
                          onChanged: (val) => setState(() => _selectedMethod = val!),
                        ),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_android, color: AppColors.primaryAccent, size: 20),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('فودافون كاش / كاش', style: AppStyles.labelBold.copyWith(fontSize: 14.sp)),
                              Text('محفظة الكاش للتحويل المباشر', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.copy_all, color: AppColors.primaryAccent, size: 18),
                              SizedBox(width: 8.w),
                              Text(
                                _vodafoneCashNumber,
                                style: AppStyles.labelBold.copyWith(fontSize: 16.sp, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _copyToClipboard(_vodafoneCashNumber, 'فودافون كاش'),
                            icon: const Icon(Icons.copy, size: 14, color: Colors.white),
                            label: const Text('نسخ الرقم', style: TextStyle(color: Colors.white, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // 2. InstaPay Card
            InkWell(
              onTap: () => setState(() => _selectedMethod = 'instapay'),
              borderRadius: BorderRadius.circular(18.r),
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _selectedMethod == 'instapay' ? AppColors.secondaryAccent.withOpacity(0.08) : AppColors.cardBg,
                  border: Border.all(
                    color: _selectedMethod == 'instapay' ? AppColors.secondaryAccent : AppColors.borderLight,
                    width: _selectedMethod == 'instapay' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: 'instapay',
                          groupValue: _selectedMethod,
                          activeColor: AppColors.secondaryAccent,
                          onChanged: (val) => setState(() => _selectedMethod = val!),
                        ),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_on, color: AppColors.secondaryAccent, size: 20),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('انستاباي (InstaPay)', style: AppStyles.labelBold.copyWith(fontSize: 14.sp)),
                              Text('تحويل بنكي فوري عبر تطبيق انستاباي', style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.copy_all, color: AppColors.secondaryAccent, size: 18),
                              SizedBox(width: 8.w),
                              Text(
                                _instapayNumber,
                                style: AppStyles.labelBold.copyWith(fontSize: 16.sp, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _copyToClipboard(_instapayNumber, 'انستاباي'),
                            icon: const Icon(Icons.copy, size: 14, color: Colors.white),
                            label: const Text('نسخ الرقم', style: TextStyle(color: Colors.white, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryAccent,
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 3. Payment Proof Upload Section (InstaPay & Vodafone Cash)
            Text('إرفاق صورة إيصال التحويل (Screenshot):', style: AppStyles.labelBold.copyWith(fontSize: 12.sp)),
            SizedBox(height: 6.h),
            InkWell(
              onTap: _pickProofImage,
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: (_proofBytes != null || _proofFile != null) ? AppColors.successStart : AppColors.borderDark,
                    width: (_proofBytes != null || _proofFile != null) ? 1.5 : 1.0,
                  ),
                ),
                child: (_proofBytes == null && _proofFile == null)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryAccent),
                          SizedBox(width: 8.w),
                          Text(
                            'إضغط لإرفاق صورة إيصال التحويل (PNG, JPG حتى 5MB)',
                            style: TextStyle(color: AppColors.textDefault, fontSize: 12.sp, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: _proofBytes != null
                                ? Image.memory(
                                    _proofBytes!,
                                    width: 48.w,
                                    height: 48.w,
                                    fit: BoxFit.cover,
                                  )
                                : (_proofFile != null
                                    ? Image.file(
                                        _proofFile!,
                                        width: 48.w,
                                        height: 48.w,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.check_circle, color: AppColors.successStart)),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تم إرفاق إيصال التحويل ✓',
                                  style: TextStyle(color: AppColors.successStart, fontWeight: FontWeight.bold, fontSize: 12.sp),
                                ),
                                Text(
                                  _proofFileName ?? (_proofFile != null ? _proofFile!.path.split(Platform.pathSeparator).last : 'صورة الإيصال'),
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _proofFile = null;
                              _proofBytes = null;
                              _proofFileName = null;
                            }),
                            icon: const Icon(Icons.cancel_outlined, color: AppColors.dangerStart),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 16.h),

            // Confirm Order Inputs (If in Order Mode)
            if (isOrderMode) ...[
              Text('رقم المحفظة / الملاحظات المؤكدة للتحويل:', style: AppStyles.labelBold.copyWith(fontSize: 12.sp)),
              SizedBox(height: 6.h),
              TextField(
                controller: _senderInfoController,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'أدخل رقمك الذي حولت منه للتأكيد...',
                  hintStyle: AppStyles.bodyMuted.copyWith(fontSize: 12.sp),
                  prefixIcon: const Icon(Icons.receipt_long, color: AppColors.textMuted),
                ),
              ),
              SizedBox(height: 18.h),

              ElevatedButton(
                onPressed: () {
                  final senderInfo = _senderInfoController.text.trim();
                  final methodTitle = _selectedMethod == 'vodafone_cash' ? 'فودافون كاش' : 'انستاباي';

                  if (widget.onConfirmOrder != null) {
                    try {
                      Function.apply(widget.onConfirmOrder!, [methodTitle, senderInfo, _proofFile, _proofBytes, _proofFileName]);
                    } catch (_) {
                      try {
                        Function.apply(widget.onConfirmOrder!, [methodTitle, senderInfo, _proofFile]);
                      } catch (_) {
                        Function.apply(widget.onConfirmOrder!, [methodTitle, senderInfo]);
                      }
                    }
                  }
                  Navigator.of(context).pop();
                },
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
                    child: Text(
                      'تأكيد إرسال الطلب وإيصال التحويل',
                      style: AppStyles.labelBold.copyWith(color: Colors.white, fontSize: 15.sp),
                    ),
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: AppStyles.buttonRadius),
                ),
                child: Text('إغلاق', style: AppStyles.labelBold.copyWith(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
