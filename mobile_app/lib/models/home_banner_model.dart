class HomeBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String imageUrl;
  final String? categoryTarget;

  const HomeBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.imageUrl,
    this.categoryTarget,
  });
}
