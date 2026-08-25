import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/category_model.dart';
import '../../models/home_banner_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/whatsapp_contact_modal.dart';
import '../../widgets/product_details_modal.dart';
import 'category_detail_screen.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<HomeBannerModel> _banners = const [
    HomeBannerModel(
      id: '1',
      title: 'تيشرتات التخرج والطباعة المخصصة',
      subtitle: 'طباعة تيشرتات التخرج دفعة 26 بأجمل التصاميم والجرافيكس',
      badgeText: 'طباعة تيشرتات 👕',
      imageUrl: 'assets/product_images/tshirts.jpg',
    ),
    HomeBannerModel(
      id: '2',
      title: 'براويز الصور وكولاج الذكريات',
      subtitle: 'برواز خشبي أسود فاخر بطباعة كولاج صور وعبارات الإهداء',
      badgeText: 'براويز فاخرة 🖼️',
      imageUrl: 'assets/product_images/frames.jpg',
    ),
    HomeBannerModel(
      id: '3',
      title: 'كروت ودعوات الأفراح والزفاف',
      subtitle: 'أرقى تصاميم دعوات الزفاف بفيونكة الستان والورق الكرتوني الفاخر',
      badgeText: 'أفراح Bola 💍',
      imageUrl: 'assets/product_images/wedding_invitation.jpg',
    ),
    HomeBannerModel(
      id: '4',
      title: 'ستاندات المكتب الأكريليك واللوحات الفاخرة',
      subtitle: 'ستاند مكتب أسود فخم بحامل أقلام وحفر مذهب بالاسم واللقب',
      badgeText: 'مستلزمات مكاتب 💼',
      imageUrl: 'assets/product_images/desk_stands.jpg',
    ),
    HomeBannerModel(
      id: '5',
      title: 'الأقلام الفورية المحفورة بالاسم',
      subtitle: 'أطقم أقلام فاخرة بحفر ليزر ذهبي أو فضي للشركات والهدايا الخاصة',
      badgeText: 'أقلام فاخرة 🖋️',
      imageUrl: 'assets/product_images/pens.jpg',
    ),
    HomeBannerModel(
      id: '6',
      title: 'دروع التكريم الخشبية والأكريليك',
      subtitle: 'دروع وأوسمة شكر وتقدير مميزة للمعلمين والمدراء والشركات',
      badgeText: 'دروع وتكريم 🏆',
      imageUrl: 'assets/product_images/trophies.jpg',
    ),
    HomeBannerModel(
      id: '7',
      title: 'أعلام المكتب والشركات المعدنية',
      subtitle: 'أعلام طاولة ومكاتب مخصصة بشعار الشركة وجودة طباعة عالية',
      badgeText: 'أعلام مكاتب 🚩',
      imageUrl: 'assets/product_images/flags.jpg',
    ),
    HomeBannerModel(
      id: '8',
      title: 'الأختام الفورية والدمغات الزخرفية',
      subtitle: 'تجهيز أختام الشركات والأفراد الفورية قياس C30 بجودة عالية',
      badgeText: 'ختم فوري ✒️',
      imageUrl: 'assets/product_images/custom_stamp.jpg',
    ),
    HomeBannerModel(
      id: '9',
      title: 'المجات الحرارية وكولاج الصور',
      subtitle: 'مجات حرارية سيراميك مطبوعة بأجمل كولاج صور عائلية وشخصية',
      badgeText: 'هدايا مخصصة ☕',
      imageUrl: 'assets/product_images/family_mug.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: 900);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      final currentUser = context.read<AuthProvider>().currentUser;
      context.read<NotificationProvider>().fetchNotifications(currentUser: currentUser);
      context.read<OrderProvider>().fetchOrders(currentUser: currentUser);
    });

    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients && _bannerController.page != null) {
        _bannerController.nextPage(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final banner in _banners) {
      if (banner.imageUrl.startsWith('assets/')) {
        precacheImage(AssetImage(banner.imageUrl), context);
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSmartImage(String? imagePath, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return _buildPlaceholderIcon();
    }

    final trimmedPath = imagePath.trim();

    // 1. Direct local asset image
    if (trimmedPath.startsWith('assets/')) {
      return Image.asset(
        trimmedPath,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
      );
    }

    // 2. Network image or filename
    final filename = trimmedPath.split('/').last;
    final fullUrl = trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')
        ? trimmedPath
        : 'https://kxeqayzxfvoedqvilcmp.supabase.co/storage/v1/object/public/product_images/$filename';

    return Image.network(
      fullUrl,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/product_images/$filename',
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/product_images/frames.jpg',
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.white.withOpacity(0.06),
      child: const Center(
        child: Icon(Icons.style_rounded, color: AppColors.primaryAccent, size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final user = authProvider.currentUser;
    final products = productProvider.products;

    return Scaffold(
      body: RadialBackground(
        child: Column(
          children: [
            AppLogoBar(username: user?.username ?? 'مرحباً بك في بولا ديزاينز'),

            // Search Bar at Top of Home Page
            _buildSearchBar(),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<ProductProvider>().fetchProducts();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: _searchQuery.isNotEmpty
                      ? _buildSearchResults(products, productProvider)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Promotional Services Banner Carousel
                            _buildBannerCarousel(),
                            SizedBox(height: 20.h),

                            // 2. Explore Categories Grid Section
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                'تصفح الفئات',
                                style: AppStyles.titleMedium.copyWith(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            _buildCategoriesGrid(),
                            SizedBox(height: 24.h),

                            // 3. Offers & Discounts Section
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                'العروض والمنتجات المميزة 🏷️',
                                style: AppStyles.titleMedium.copyWith(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            _buildBestSellersGrid(products, productProvider),
                            SizedBox(height: 20.h),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => WhatsAppContactModal.show(context),
        backgroundColor: AppColors.primaryAccent,
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentRoute: 'home',
        isAdmin: user?.isAdmin ?? false,
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 160.h,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index % _banners.length;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index % _banners.length];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12.r,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Stack(
                    children: [
                      // 1. Full Background Image taking up the entire banner
                      Positioned.fill(
                        child: _buildSmartImage(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),

                      // 2. Dark Gradient Overlay for optimal text readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.82),
                                Colors.black.withOpacity(0.45),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomRight,
                              end: Alignment.topLeft,
                            ),
                          ),
                        ),
                      ),

                      // 3. Text Overlay Content
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(14.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  banner.badgeText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                banner.title,
                                style: AppStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                banner.subtitle,
                                style: AppStyles.bodyMuted.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isSelected = index == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              height: 8.h,
              width: isSelected ? 24.w : 8.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryAccent : AppColors.borderDark,
                borderRadius: BorderRadius.circular(10.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _searchQuery.isNotEmpty ? AppColors.primaryAccent : AppColors.borderLight,
          width: _searchQuery.isNotEmpty ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.r,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        style: TextStyle(fontSize: 14.sp, color: AppColors.textMain),
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج، قسم، برواز، مج، تيشيرت...',
          hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchQuery.isNotEmpty ? AppColors.primaryAccent : AppColors.textMuted,
            size: 22.r,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 20.r),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<ProductModel> products, ProductProvider productProvider) {
    final cleanQuery = _searchQuery.toLowerCase();
    final categories = productProvider.categories;

    final filteredCategories = categories.where((cat) {
      final matchName = cat.title.toLowerCase().contains(cleanQuery);
      final matchSub = cat.subCategories.any((sub) => sub.toLowerCase().contains(cleanQuery));
      return matchName || matchSub;
    }).toList();

    final filteredProducts = products.where((prod) {
      final matchName = prod.name.toLowerCase().contains(cleanQuery);
      final matchDesc = prod.description.toLowerCase().contains(cleanQuery);
      return matchName || matchDesc;
    }).toList();

    final filteredBanners = _banners.where((b) {
      return b.title.toLowerCase().contains(cleanQuery) ||
             b.subtitle.toLowerCase().contains(cleanQuery) ||
             b.badgeText.toLowerCase().contains(cleanQuery);
    }).toList();

    final totalResults = filteredCategories.length + filteredProducts.length + filteredBanners.length;

    if (totalResults == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded, color: AppColors.primaryAccent, size: 48.r),
              ),
              SizedBox(height: 16.h),
              Text(
                'لا توجد نتائج مطابقة لـ "$_searchQuery"',
                style: AppStyles.titleMedium.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'جرب البحث بكلمات أخرى مثل "فوتوبلوك", "مج", "تيشيرت", "ختم", "درع"',
                style: AppStyles.bodyMuted.copyWith(fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة تصفح الصفحة الرئيسية'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryAccent,
                  side: const BorderSide(color: AppColors.primaryAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results summary header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نتائج البحث عن "$_searchQuery"',
                style: AppStyles.titleMedium.copyWith(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$totalResults نتيجة',
                  style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 1. Filtered Categories
        if (filteredCategories.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'الأقسام المطابقة 📁',
              style: AppStyles.titleMedium.copyWith(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10.h),
          _buildCategoriesGrid(categoriesList: filteredCategories),
          SizedBox(height: 20.h),
        ],

        // 2. Filtered Products
        if (filteredProducts.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'المنتجات المطابقة 🛍️',
              style: AppStyles.titleMedium.copyWith(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10.h),
          _buildBestSellersGrid(filteredProducts, productProvider),
          SizedBox(height: 20.h),
        ],

        // 3. Filtered Banners / Services
        if (filteredBanners.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'العروض والخدمات ذات الصلة 🌟',
              style: AppStyles.titleMedium.copyWith(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10.h),
          ...filteredBanners.map((banner) => Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    width: 54.r,
                    height: 54.r,
                    child: _buildSmartImage(banner.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.badgeText,
                        style: TextStyle(color: AppColors.primaryAccent, fontSize: 10.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        banner.title,
                        style: AppStyles.labelBold.copyWith(fontSize: 13.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        banner.subtitle,
                        style: AppStyles.bodyMuted.copyWith(fontSize: 11.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }

  Widget _buildCategoriesGrid({List<CategoryModel>? categoriesList}) {
    final productProvider = context.watch<ProductProvider>();
    final categories = categoriesList ?? productProvider.categories;

    if (categories.isEmpty && productProvider.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenUtil().screenWidth > 600 ? 5 : 3,
          childAspectRatio: 0.78,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(category: cat),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: cat.title.contains('ورقيات')
                      ? AppColors.primaryAccent
                      : AppColors.borderLight,
                  width: cat.title.contains('ورقيات') ? 1.8 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8.r,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6.r,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: _buildSmartImage(
                        cat.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    cat.title,
                    textAlign: TextAlign.center,
                    style: AppStyles.labelBold.copyWith(fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cat.subCategoriesCount > 0) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '${cat.subCategoriesCount} فئات فرعية',
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBestSellersGrid(List<ProductModel> products, ProductProvider provider) {
    if (provider.isLoading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
    }

    if (products.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 40.r),
              SizedBox(height: 8.h),
              Text('لا توجد منتجات مضافة حالياً في المتجر', style: AppStyles.bodyMuted),
            ],
          ),
        ),
      );
    }

    final displayProducts = products;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenUtil().screenWidth > 600 ? 3 : 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: displayProducts.length,
        itemBuilder: (context, index) {
          final product = displayProducts[index];
          final discount = (index % 2 == 0) ? '${12 + index * 3}% OFF' : null;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10.r,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image + Badges (Tap to open ProductDetailsModal)
                Expanded(
                  child: GestureDetector(
                    onTap: () => ProductDetailsModal.show(context, product),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                            child: _buildSmartImage(
                              product.imageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        // Top Left Badge
                        Positioned(
                          top: 8.h,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'عرض خاص',
                              style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        // Discount Badge
                        if (discount != null)
                          Positioned(
                            bottom: 8.h,
                            left: 8.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.textDefault,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                discount,
                                style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Details & Add to Cart Action
                Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => ProductDetailsModal.show(context, product),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: AppStyles.labelBold.copyWith(fontSize: 13.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'انقر للاطلاع على المواصفات والوصف 📋',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.price <= 0 ? 'تواصل معنا' : '${product.price % 1 == 0 ? product.price.toInt() : product.price.toStringAsFixed(2)} ج.م',
                                style: TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'توصيل سريع',
                                  style: TextStyle(color: AppColors.primaryAccent, fontSize: 8.sp),
                                ),
                              ),
                            ],
                          ),

                          // Cart Action button (+ / quantity controls)
                          Builder(
                            builder: (context) {
                              final cartProvider = context.watch<CartProvider>();
                              final itemIdx = cartProvider.items.indexWhere((it) => it.product.id == product.id);
                              final inCartQty = itemIdx >= 0 ? cartProvider.items[itemIdx].quantity : 0;

                              if (inCartQty == 0) {
                                return InkWell(
                                  onTap: () {
                                    cartProvider.addToCart(product);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const CartScreen()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent,
                                      borderRadius: BorderRadius.circular(10.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryAccent.withOpacity(0.3),
                                          blurRadius: 6.r,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16.r),
                                        SizedBox(width: 3.w),
                                        Icon(Icons.add, color: Colors.white, size: 15.r),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => cartProvider.updateQuantity(product.id, inCartQty - 1),
                                        child: Padding(
                                          padding: EdgeInsets.all(2.r),
                                          child: Icon(
                                            inCartQty > 1 ? Icons.remove : Icons.delete_outline,
                                            color: inCartQty > 1 ? AppColors.primaryAccent : AppColors.dangerStart,
                                            size: 16.r,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => const CartScreen()),
                                            );
                                          },
                                          child: Text(
                                            '$inCartQty',
                                            style: TextStyle(
                                              color: AppColors.primaryAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => cartProvider.updateQuantity(product.id, inCartQty + 1),
                                        child: Padding(
                                          padding: EdgeInsets.all(2.r),
                                          child: Icon(Icons.add, color: AppColors.primaryAccent, size: 16.r),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
