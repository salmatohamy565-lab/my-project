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
import '../../services/api_service.dart';
import '../../widgets/app_logo_bar.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/radial_background.dart';
import '../../widgets/whatsapp_contact_modal.dart';
import 'category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

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
    });

    _bannerTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_bannerController.hasClients && _bannerController.page != null) {
        _bannerController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
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
    super.dispose();
  }

  Widget _buildSmartImage(String? imagePath, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholderIcon();
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
      );
    }
    final fullUrl = imagePath.startsWith('http') ? imagePath : ApiService().baseUrl + imagePath;
    return Image.network(
      fullUrl,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
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

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<ProductProvider>().fetchProducts();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Column(
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
                      Padding(
                        padding: EdgeInsets.all(16.w),
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
                            SizedBox(height: 6.h),
                            Text(
                              banner.title,
                              style: AppStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    offset: const Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              banner.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11.sp,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    offset: const Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

  Widget _buildCategoriesGrid() {
    final categories = CategoryModel.defaultCategories;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenUtil().screenWidth > 600 ? 5 : 3,
          childAspectRatio: 0.85,
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
                  color: cat.id == 'paperwork'
                      ? AppColors.primaryAccent
                      : AppColors.borderLight,
                  width: cat.id == 'paperwork' ? 1.8 : 1.0,
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
                  if (cat.subCategories.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '${cat.subCategories.length} فئات فرعية',
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

    final displayProducts = products.isEmpty ? _getSampleProducts() : products;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenUtil().screenWidth > 600 ? 3 : 2,
          childAspectRatio: 0.72,
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
                // Top Image + Badges
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                          child: _buildSmartImage(
                            product.imageUrl,
                            fit: BoxFit.cover,
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

                // Details & Add to Cart Action
                Padding(
                  padding: EdgeInsets.all(10.w),
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
                        'خصم مميز لفترة محدودة ⚡',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.price % 1 == 0 ? product.price.toInt() : product.price.toStringAsFixed(2)} ج.م',
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

                          // (+) Add to Cart button
                          InkWell(
                            onTap: () {
                              context.read<CartProvider>().addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🛒 تم إضافة "${product.name}" إلى السلة!'),
                                  backgroundColor: AppColors.primaryAccent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 16.r,
                              backgroundColor: AppColors.primaryAccent,
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
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

  List<ProductModel> _getSampleProducts() {
    return [
      ProductModel(
        id: 1,
        name: 'تيشرت تخرج قطن أسود كوستوم جرافيك 2026',
        description: 'طباعة تيشرتات تخرج وجرافيكس مخصصة بأعلى جودة',
        price: 280,
        imageUrl: 'assets/product_images/tshirts.jpg',
      ),
      ProductModel(
        id: 2,
        name: 'برواز خشبي أسود فخم كولاج صور وذكريات',
        description: 'برواز مودرن بعبارات وإهداءات مخصصة وكولاج صور',
        price: 240,
        imageUrl: 'assets/product_images/frames.jpg',
      ),
      ProductModel(
        id: 3,
        name: 'كروت ودعوات زفاف فاخرة بشرائط الستان',
        description: 'تصميم كروت ودعوات أفراح وزفاف فاخرة',
        price: 45,
        imageUrl: 'assets/product_images/wedding_invitation.jpg',
      ),
      ProductModel(
        id: 4,
        name: 'ستاند مكتب أكريليك أسود وحامل أقلام مذهب',
        description: 'ستاند مكتب فخم حفر ليزر مذهب بالاسم واللقب',
        price: 350,
        imageUrl: 'assets/product_images/desk_stands.jpg',
      ),
      ProductModel(
        id: 5,
        name: 'طقم أقلام فاخرة بحفر ليزر مذهب',
        description: 'أقلام سوداء أنيقة محفورة بالاسم للشركات والهدايا',
        price: 220,
        imageUrl: 'assets/product_images/pens.jpg',
      ),
      ProductModel(
        id: 6,
        name: 'درع تكريم أكريليك وخشب للشكر والتقدير',
        description: 'دروع تكريم فاخرة للمعلمين والمدراء والشركات',
        price: 290,
        imageUrl: 'assets/product_images/trophies.jpg',
      ),
      ProductModel(
        id: 7,
        name: 'علم مكتب معدني فاخر باللوجو والاسم',
        description: 'علم طاولة ومكتب مخصص باللوجو والاسم للشركات',
        price: 120,
        imageUrl: 'assets/product_images/flags.jpg',
      ),
      ProductModel(
        id: 8,
        name: 'ختم فوري مستطيل C30 بزخرفة مخصصة',
        description: 'ختم فوري مخصص للشركات والمكاتب والأفراد',
        price: 180,
        imageUrl: 'assets/product_images/custom_stamp.jpg',
      ),
      ProductModel(
        id: 9,
        name: 'مج حراري سيراميك كولاج صور عائلي',
        description: 'مج مطبوع كولاج صور حراري بالاسم والصورة',
        price: 150,
        imageUrl: 'assets/product_images/family_mug.jpg',
      ),
    ];
  }
}
