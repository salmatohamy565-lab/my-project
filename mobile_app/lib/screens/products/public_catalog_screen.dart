import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../login_screen.dart';

class CategoryItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;

  const CategoryItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
  });
}

class PublicCatalogScreen extends StatefulWidget {
  final String? userName;
  const PublicCatalogScreen({super.key, this.userName});

  @override
  State<PublicCatalogScreen> createState() => _PublicCatalogScreenState();
}

class _PublicCatalogScreenState extends State<PublicCatalogScreen> {
  int _selectedNavIndex = 1; // 0: Account, 1: Home, 2: Cart
  String _selectedCategoryId = 'papers'; // Default selected item matching screenshot

  final List<CategoryItem> _categories = const [
    CategoryItem(id: 'mugs', title: 'مجات', icon: Icons.coffee_outlined),
    CategoryItem(id: 'frames', title: 'براويز', icon: Icons.crop_original_outlined),
    CategoryItem(id: 'wedding_supplies', title: 'مستلزمات افراح', icon: Icons.favorite_outline),
    CategoryItem(id: 'medals', title: 'ميداليات', icon: Icons.military_tech_outlined),
    CategoryItem(id: 'certificates', title: 'شهادات', icon: Icons.gavel_rounded),
    CategoryItem(id: 'tablohat', title: 'تابلوهات', icon: Icons.photo_size_select_actual_outlined),
    CategoryItem(id: 'trophies', title: 'دروع', icon: Icons.emoji_events_outlined),
    CategoryItem(id: 'tshirts', title: 'تيشرتات', icon: Icons.person_outline),
    CategoryItem(id: 'wallets', title: 'محافظ', icon: Icons.account_balance_wallet_outlined),
    CategoryItem(id: 'flags', title: 'اعلام', icon: Icons.flag_outlined),
    CategoryItem(id: 'desk_stand', title: 'ستاند مكتب', icon: Icons.desktop_windows_outlined),
    CategoryItem(id: 'pens', title: 'اقلام', icon: Icons.edit_outlined),
    CategoryItem(id: 'papers', title: 'ورقيات', subtitle: '4 فئات فرعية', icon: Icons.description_outlined),
    CategoryItem(id: 'wedding_cards', title: 'كروت افراح', icon: Icons.style_outlined),
    CategoryItem(id: 'stamps', title: 'اختام', icon: Icons.article_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchPublicProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final publicProducts = productProvider.publicProducts;
    final currentUser = authProvider.currentUser;

    final displayName = widget.userName ?? currentUser?.username ?? 'malakmoatasem0008780';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Header Bar ──
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: User Info
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 38.r,
                              height: 38.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: Colors.black87),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              displayName,
                              style: AppStyles.labelBold.copyWith(
                                fontSize: 13.sp,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: Logo
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'FOR ADVERTISING',
                                style: TextStyle(
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'BOLA DESIGNS',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '01222856926',
                                style: TextStyle(
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 6.w),
                          Image.asset(
                            'assets/bola_logo.png',
                            width: 32.w,
                            height: 32.w,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.palette_outlined,
                              size: 28,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Main Content Area ──
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<ProductProvider>().fetchPublicProducts(),
                    color: AppColors.primaryAccent,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories Grid (3 Columns)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _categories.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10.w,
                              mainAxisSpacing: 10.h,
                              childAspectRatio: 0.76,
                            ),
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = cat.id == _selectedCategoryId;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = cat.id;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18.r),
                                    border: Border.all(
                                      color: isSelected ? Colors.black : Colors.transparent,
                                      width: isSelected ? 2 : 0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Category Icon Box
                                      Container(
                                        width: 46.r,
                                        height: 46.r,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(14.r),
                                        ),
                                        child: Icon(
                                          cat.icon,
                                          size: 22.sp,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          cat.title,
                                          style: AppStyles.labelBold.copyWith(
                                            fontSize: 12.sp,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      if (cat.subtitle != null) ...[
                                        SizedBox(height: 2.h),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            cat.subtitle!,
                                            style: AppStyles.bodyMuted.copyWith(
                                              fontSize: 9.sp,
                                              color: Colors.grey.shade600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 24.h),

                          // Best Sellers Title Section
                          Text(
                            'Best sellers',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 14.h),

                          // Best Sellers Products Horizontal List
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildSampleBestSellerCard(
                                  title: 'ورقيات ممتازة',
                                  price: '150 ج.م',
                                ),
                                SizedBox(width: 14.w),
                                _buildSampleBestSellerCard(
                                  title: 'كروت طباعة فاخرة',
                                  price: '200 ج.م',
                                ),
                                SizedBox(width: 14.w),
                                _buildSampleBestSellerCard(
                                  title: 'تابلوه خشب VIP',
                                  price: '350 ج.م',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 80.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Floating Chat Button (Bottom Left) ──
            Positioned(
              left: 20.w,
              bottom: 80.h,
              child: Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الدعم الفني: 01222856926')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Navigation Bar ──
      bottomNavigationBar: Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.person_outline,
              label: 'Account',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.home_rounded,
              label: 'Home',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.shopping_cart_outlined,
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
        if (index == 0) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey.shade400,
              size: 22.sp,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleBestSellerCard({
    required String title,
    required String price,
  }) {
    return Container(
      width: 160.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 110.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: const Center(
                  child: Icon(Icons.description_outlined, size: 40, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 10.h,
                left: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Best Seller',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10.h,
                right: 10.w,
                child: const Icon(Icons.favorite_border, color: Colors.black54),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.labelBold.copyWith(fontSize: 13.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
