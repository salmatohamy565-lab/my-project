import 'product_model.dart';

class OrderModel {
  final int id;
  final int userId;
  final String productIds;
  final List<ProductModel> products;
  final String status; // pending, cancelled, cart, payment_proof_submitted
  final double totalPrice;
  final String? paymentMethod;
  final String? paymentProofUrl;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.productIds,
    this.products = const [],
    required this.status,
    required this.totalPrice,
    this.paymentMethod,
    this.paymentProofUrl,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawProducts = json['products'] as List? ?? [];
    List<ProductModel> prodList = rawProducts
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      productIds: json['product_ids']?.toString() ?? '',
      products: prodList,
      status: json['status']?.toString() ?? 'pending',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString(),
      paymentProofUrl: json['payment_proof_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_ids': productIds,
      'status': status,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'payment_proof_url': paymentProofUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
