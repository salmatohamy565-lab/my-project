import 'package:flutter/material.dart';
import 'subcategory_model.dart';

class CategoryModel {
  final int id;
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final List<SubcategoryModel> subCategoriesList;
  final int subCategoriesCount;
  final String imageUrl;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.imageUrl,
    this.subCategoriesList = const [],
    this.subCategoriesCount = 0,
  });

  List<String> get subCategories => subCategoriesList.map((s) => s.name).toList();

  factory CategoryModel.fromSupabase(Map<String, dynamic> json, {List<SubcategoryModel> subcats = const []}) {
    final int catId = json['id'] is int ? json['id'] : int.parse(json['id'].toString());
    final String catName = json['name'] ?? '';

    // Match visual presets by title / name
    final preset = _getPresetByName(catName);

    final rawSubCount = json['subcategories_count'] ?? json['subcategories']?.length;
    final int count = rawSubCount != null ? int.tryParse(rawSubCount.toString()) ?? subcats.length : subcats.length;

    return CategoryModel(
      id: catId,
      title: catName,
      icon: preset.icon,
      gradientColors: preset.gradientColors,
      imageUrl: (json['image_url'] != null && json['image_url'].toString().trim().isNotEmpty)
          ? json['image_url'].toString().trim()
          : preset.imageUrl,
      subCategoriesList: subcats,
      subCategoriesCount: count,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? title,
    IconData? icon,
    List<Color>? gradientColors,
    List<SubcategoryModel>? subCategoriesList,
    int? subCategoriesCount,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      gradientColors: gradientColors ?? this.gradientColors,
      subCategoriesList: subCategoriesList ?? this.subCategoriesList,
      subCategoriesCount: subCategoriesCount ?? this.subCategoriesCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  static _CategoryPreset _getPresetByName(String name) {
    final normName = _normalizeArabic(name);

    if (normName.contains('عرض') || normName.contains('عروض') || normName.contains('خصم')) {
      return const _CategoryPreset(
        icon: Icons.local_offer_rounded,
        gradientColors: [Color(0xFFE63946), Color(0xFFD90429)],
        imageUrl: 'assets/product_images/special_offer.jpg',
      );
    }

    if (normName.contains('افراح') || normName.contains('زفاف') || normName.contains('مستلزمات')) {
      return const _CategoryPreset(
        icon: Icons.favorite_rounded,
        gradientColors: [Color(0xFF343A40), Color(0xFF212529)],
        imageUrl: 'assets/product_images/wedding_invitation_ribbon.jpg',
      );
    }
    if (normName.contains('فوتوبلوك') || normName.contains('براويز') || normName.contains('بروار')) {
      return const _CategoryPreset(
        icon: Icons.photo_library_rounded,
        gradientColors: [Color(0xFF495057), Color(0xFF343A40)],
        imageUrl: 'assets/product_images/frames.jpg',
      );
    }
    if (normName.contains('مج')) {
      return const _CategoryPreset(
        icon: Icons.local_cafe_rounded,
        gradientColors: [Color(0xFF6C757D), Color(0xFF495057)],
        imageUrl: 'assets/product_images/mug_white_real.jpg',
      );
    }
    if (normName.contains('تابلوه')) {
      return const _CategoryPreset(
        icon: Icons.palette_rounded,
        gradientColors: [Color(0xFF212529), Color(0xFF0A0A0A)],
        imageUrl: 'assets/product_images/tableaux.jpg',
      );
    }
    if (normName.contains('شهادات') || normName.contains('شهاده')) {
      return const _CategoryPreset(
        icon: Icons.workspace_premium_rounded,
        gradientColors: [Color(0xFF495057), Color(0xFF212529)],
        imageUrl: 'assets/product_images/cert_navy_gold.jpg',
      );
    }
    if (normName.contains('ميدالي')) {
      return const _CategoryPreset(
        icon: Icons.military_tech_rounded,
        gradientColors: [Color(0xFF6C757D), Color(0xFF343A40)],
        imageUrl: 'assets/product_images/keychain_soft_photo.jpg',
      );
    }
    if (normName.contains('درع') || normName.contains('دروع')) {
      return const _CategoryPreset(
        icon: Icons.emoji_events_rounded,
        gradientColors: [Color(0xFF212529), Color(0xFF0A0A0A)],
        imageUrl: 'assets/product_images/trophies.jpg',
      );
    }
    if (normName.contains('تيشرت') || normName.contains('تيشيرت')) {
      return const _CategoryPreset(
        icon: Icons.checkroom_rounded,
        gradientColors: [Color(0xFF495057), Color(0xFF212529)],
        imageUrl: 'assets/product_images/tshirts.jpg',
      );
    }
    if (normName.contains('محافظ') || normName.contains('محفظه') || normName.contains('محفظ')) {
      return const _CategoryPreset(
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: [Color(0xFF343A40), Color(0xFF0A0A0A)],
        imageUrl: 'assets/product_images/wallet_engraved_group.jpg',
      );
    }
    if (normName.contains('علم') || normName.contains('اعلام')) {
      return const _CategoryPreset(
        icon: Icons.flag_rounded,
        gradientColors: [Color(0xFF495057), Color(0xFF343A40)],
        imageUrl: 'assets/product_images/flags.jpg',
      );
    }
    if (normName.contains('ستاند') || normName.contains('مكتب')) {
      return const _CategoryPreset(
        icon: Icons.desktop_mac_rounded,
        gradientColors: [Color(0xFF343A40), Color(0xFF212529)],
        imageUrl: 'assets/product_images/desk_stands.jpg',
      );
    }
    if (normName.contains('قلم') || normName.contains('اقلام')) {
      return const _CategoryPreset(
        icon: Icons.create_rounded,
        gradientColors: [Color(0xFF6C757D), Color(0xFF495057)],
        imageUrl: 'assets/product_images/pens.jpg',
      );
    }
    if (normName.contains('ورق')) {
      return const _CategoryPreset(
        icon: Icons.description_rounded,
        gradientColors: [Color(0xFF343A40), Color(0xFF0A0A0A)],
        imageUrl: 'assets/product_images/tableau_desk_wall_collage.jpg',
      );
    }
    if (normName.contains('ختم') || normName.contains('اختام')) {
      return const _CategoryPreset(
        icon: Icons.approval_rounded,
        gradientColors: [Color(0xFF212529), Color(0xFF0A0A0A)],
        imageUrl: 'assets/product_images/custom_stamp.jpg',
      );
    }

    return const _CategoryPreset(
      icon: Icons.category_rounded,
      gradientColors: [Color(0xFF343A40), Color(0xFF212529)],
      imageUrl: 'assets/product_images/frames.jpg',
    );
  }

  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[أإآآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ـ', '');
  }
}

class _CategoryPreset {
  final IconData icon;
  final List<Color> gradientColors;
  final String imageUrl;

  const _CategoryPreset({
    required this.icon,
    required this.gradientColors,
    required this.imageUrl,
  });
}
