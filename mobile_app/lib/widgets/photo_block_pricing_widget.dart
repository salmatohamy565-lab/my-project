import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class PhotoBlockPricingWidget extends StatefulWidget {
  final bool isCompact;
  final Function(String type, String size, double price)? onSizeSelected;

  const PhotoBlockPricingWidget({
    super.key,
    this.isCompact = false,
    this.onSizeSelected,
  });

  @override
  State<PhotoBlockPricingWidget> createState() => _PhotoBlockPricingWidgetState();
}

class _PhotoBlockPricingWidgetState extends State<PhotoBlockPricingWidget> {
  int _selectedCategoryIndex = 0; // 0: فوتوبلوك خشب, 1: برواز مسطرة, 2: برواز جامبو

  static const List<Map<String, dynamic>> _pricingData = [
    {
      'title': 'فوتوبلوك خشب 🪵',
      'subtitle': 'طباعة حرارية عالية الدقة على خشب MDF فاخر',
      'color': Colors.amber,
      'items': [
        {'size': '15 x 20 سم', 'price': 90.0},
        {'size': '20 x 30 سم', 'price': 150.0},
        {'size': '30 x 40 سم', 'price': 200.0},
        {'size': '40 x 50 سم', 'price': 300.0},
        {'size': '50 x 60 سم', 'price': 350.0},
        {'size': '50 x 70 سم', 'price': 400.0},
        {'size': '60 x 90 سم', 'price': 500.0},
      ]
    },
    {
      'title': 'برواز مسطرة 🖼️',
      'subtitle': 'إطار كلاسيكي مسطرة بألوان فاخرة وحماية زجاجية',
      'color': Colors.blueAccent,
      'items': [
        {'size': '10 x 15 سم', 'price': 60.0},
        {'size': '15 x 20 سم', 'price': 90.0},
        {'size': '20 x 30 سم', 'price': 150.0},
        {'size': '30 x 40 سم', 'price': 200.0},
        {'size': '40 x 50 سم', 'price': 300.0},
        {'size': '50 x 60 سم', 'price': 350.0},
        {'size': '50 x 70 سم', 'price': 400.0},
      ]
    },
    {
      'title': 'برواز جامبو 🏆',
      'subtitle': 'إطار فخم بارز بظهر متين وعمق مميز للأماكن الكبيرة',
      'color': Colors.purpleAccent,
      'items': [
        {'size': '15 x 20 سم', 'price': 130.0},
        {'size': '20 x 30 سم', 'price': 220.0},
        {'size': '30 x 40 سم', 'price': 280.0},
        {'size': '40 x 50 سم', 'price': 400.0},
        {'size': '50 x 60 سم', 'price': 450.0},
        {'size': '50 x 70 سم', 'price': 500.0},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeData = _pricingData[_selectedCategoryIndex];
    final Color categoryColor = activeData['color'];
    final List<dynamic> items = activeData['items'];

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppStyles.cardRadius,
        border: Border.all(color: categoryColor.withOpacity(0.4), width: 1.5),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.straighten_rounded, color: categoryColor, size: 22.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeData['title'],
                      style: AppStyles.titleMedium.copyWith(fontSize: 15.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      activeData['subtitle'],
                      style: AppStyles.bodyMuted.copyWith(fontSize: 10.5.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Category Selector Tabs
          Row(
            children: List.generate(_pricingData.length, (idx) {
              final isSelected = _selectedCategoryIndex == idx;
              final cat = _pricingData[idx];
              final catColor = cat['color'] as Color;
              final String fullTitle = cat['title'].toString();
              // Clean tab title: e.g. "فوتوبلوك", "برواز مسطرة", "برواز جامبو"
              final String tabLabel = fullTitle.contains('فوتوبلوك')
                  ? 'فوتوبلوك 🪵'
                  : fullTitle.contains('جامبو')
                      ? 'برواز جامبو 🏆'
                      : 'برواز مسطرة 🖼️';

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? catColor : AppColors.borderLight,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      tabLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? catColor : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 14.h),

          // Header Bar of Table
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المقاس (سم)', style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                Text('السعر والطلب 🛒', style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold, fontSize: 12.sp)),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Sizes & Prices List / Grid
          Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final size = item['size'].toString();
              final price = (item['price'] as num).toDouble();
              final isEven = index % 2 == 0;

              return InkWell(
                onTap: () {
                  if (widget.onSizeSelected != null) {
                    widget.onSizeSelected!(activeData['title'], size, price);
                  }
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  margin: EdgeInsets.only(bottom: 6.h),
                  decoration: BoxDecoration(
                    color: isEven ? AppColors.inputBg.withOpacity(0.6) : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: categoryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.aspect_ratio_rounded, size: 18.r, color: categoryColor),
                          SizedBox(width: 8.w),
                          Text(
                            size,
                            style: AppStyles.bodyDefault.copyWith(fontWeight: FontWeight.bold, fontSize: 13.5.sp),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${price.toStringAsFixed(0)} ج.م',
                              style: TextStyle(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'أطلب',
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5.sp,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10.r, color: categoryColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
