import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> subCategories;
  final String imageUrl;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.imageUrl,
    this.subCategories = const [],
  });

  // Strict Gray & White / Slate design palette - zero purple
  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 'wedding',
      title: 'مستلزمات افراح',
      icon: Icons.favorite_rounded,
      gradientColors: [Color(0xFF343A40), Color(0xFF212529)],
      imageUrl: 'assets/product_images/wedding_invitation.jpg',
    ),
    CategoryModel(
      id: 'frames',
      title: 'براويز',
      icon: Icons.crop_original_rounded,
      gradientColors: [Color(0xFF495057), Color(0xFF343A40)],
      imageUrl: 'assets/product_images/frames.jpg',
    ),
    CategoryModel(
      id: 'mugs',
      title: 'مجات',
      icon: Icons.local_cafe_rounded,
      gradientColors: [Color(0xFF6C757D), Color(0xFF495057)],
      imageUrl: 'assets/product_images/family_mug.jpg',
    ),
    CategoryModel(
      id: 'tablohs',
      title: 'تابلوهات',
      icon: Icons.palette_rounded,
      gradientColors: [Color(0xFF212529), Color(0xFF0A0A0A)],
      imageUrl: 'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?w=500',
    ),
    CategoryModel(
      id: 'certificates',
      title: 'شهادات',
      icon: Icons.workspace_premium_rounded,
      gradientColors: [Color(0xFF495057), Color(0xFF212529)],
      imageUrl: 'assets/product_images/certificate.jpg',
    ),
    CategoryModel(
      id: 'medals',
      title: 'ميداليات',
      icon: Icons.military_tech_rounded,
      gradientColors: [Color(0xFF6C757D), Color(0xFF343A40)],
      imageUrl: 'assets/product_images/keychains.jpg',
    ),
    CategoryModel(
      id: 'trophies',
      title: 'دروع',
      icon: Icons.emoji_events_rounded,
      gradientColors: [Color(0xFF212529), Color(0xFF0A0A0A)],
      imageUrl: 'assets/product_images/trophies.jpg',
    ),
    CategoryModel(
      id: 'tshirts',
      title: 'تيشرتات',
      icon: Icons.checkroom_rounded,
      gradientColors: [Color(0xFF495057), Color(0xFF212529)],
      imageUrl: 'assets/product_images/tshirts.jpg',
    ),
    CategoryModel(
      id: 'wallets',
      title: 'محافظ',
      icon: Icons.account_balance_wallet_rounded,
      gradientColors: [Color(0xFF343A40), Color(0xFF0A0A0A)],
      imageUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=500',
    ),
    CategoryModel(
      id: 'flags',
      title: 'اعلام',
      icon: Icons.flag_rounded,
      gradientColors: [Color(0xFF495057), Color(0xFF343A40)],
      imageUrl: 'assets/product_images/flags.jpg',
    ),
    CategoryModel(
      id: 'desk_stands',
      title: 'ستاند مكتب',
      icon: Icons.desktop_mac_rounded,
      gradientColors: [Color(0xFF343A40), Color(0xFF212529)],
      imageUrl: 'assets/product_images/desk_stands.jpg',
    ),
    CategoryModel(
      id: 'pens',
      title: 'اقلام',
      icon: Icons.create_rounded,
      gradientColors: [Color(0xFF6C757D), Color(0xFF495057)],
      imageUrl: 'assets/product_images/pens.jpg',
    ),
    CategoryModel(
      id: 'paperwork',
      title: 'ورقيات',
      icon: Icons.description_rounded,
      gradientColors: [Color(0xFF343A40), Color(0xFF0A0A0A)],
      imageUrl: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=500',
      subCategories: [
        'ورق دعايا',
        'كروت شخصيه',
        'روشتات',
        'منيوهات',
      ],
    ),
    CategoryModel(
      id: 'stamps',
      title: 'اختام',
      icon: Icons.approval_rounded,
      gradientColors: [Color(0xFF212529), Color(0xFF0A0A0A)],
      imageUrl: 'assets/product_images/custom_stamp.jpg',
    ),
  ];
}
