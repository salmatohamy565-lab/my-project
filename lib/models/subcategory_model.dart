class SubcategoryModel {
  final int id;
  final int categoryId;
  final String name;
  final DateTime? createdAt;

  SubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.createdAt,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      categoryId: json['category_id'] is int ? json['category_id'] : int.parse(json['category_id'].toString()),
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
