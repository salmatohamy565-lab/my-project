class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Helper to resolve dynamic server address
  String? getFullImageUrl(String baseUrl) {
    if (imageUrl == null) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;
    // Remove leading slash if it exists
    final path = imageUrl!.startsWith('/') ? imageUrl!.substring(1) : imageUrl;
    return '$baseUrl/$path';
  }
}
