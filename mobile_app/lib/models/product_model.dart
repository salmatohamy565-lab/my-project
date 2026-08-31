class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final int? categoryId;
  final int? subcategoryId;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.categoryId,
    this.subcategoryId,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? img = json['image_url'] ?? json['image_filename'] ?? json['image'];
    if (img != null && img.isNotEmpty && !img.startsWith('http') && !img.startsWith('data:')) {
      if (img.startsWith('/')) {
        img = img.substring(1);
      }
      if (!img.startsWith('uploads/')) {
        img = 'https://kxeqayzxfvoedqvilcmp.supabase.co/storage/v1/object/public/product_images/$img';
      }
    }

    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    return ProductModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: img,
      categoryId: parseId(json['category_id']),
      subcategoryId: parseId(json['subcategory_id']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String? getFullImageUrl(String baseUrl) {
    if (imageUrl == null) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;
    final path = imageUrl!.startsWith('/') ? imageUrl!.substring(1) : imageUrl;
    return '$baseUrl/$path';
  }
}
