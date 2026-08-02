import 'product_model.dart';

class OrderModel {
  final int id;
  final int userId;
  final String customerName;
  final String customerPhone;
  final String productIds;
  final String itemsSummary;
  final List<ProductModel> products;
  final String status; // pending, preparing, ready, delivered, rejected, cancelled, cart
  final double totalPrice;
  final String? paymentMethod;
  final String? paymentProofUrl;
  final String? rejectionReason;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    this.customerName = '',
    this.customerPhone = '',
    required this.productIds,
    this.itemsSummary = '',
    this.products = const [],
    required this.status,
    required this.totalPrice,
    this.paymentMethod,
    this.paymentProofUrl,
    this.rejectionReason,
    this.createdAt,
  });

  String get statusArabic {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'preparing':
        return 'جاري التجهيز';
      case 'ready':
        return 'جاهز للتوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String? getFullPaymentProofUrl(String baseUrl) {
    if (paymentProofUrl == null || paymentProofUrl!.trim().isEmpty) return null;
    if (paymentProofUrl!.startsWith('http://') || paymentProofUrl!.startsWith('https://')) {
      return paymentProofUrl;
    }
    String cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String cleanPath = paymentProofUrl!.startsWith('/') ? paymentProofUrl! : '/$paymentProofUrl';
    return '$cleanBase$cleanPath';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawProducts = json['products'] as List? ?? [];
    List<ProductModel> prodList = rawProducts
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      productIds: json['product_ids']?.toString() ?? '',
      itemsSummary: json['items_summary']?.toString() ?? '',
      products: prodList,
      status: json['status']?.toString() ?? 'pending',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString(),
      paymentProofUrl: json['payment_proof_url']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'product_ids': productIds,
      'items_summary': itemsSummary,
      'status': status,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'payment_proof_url': paymentProofUrl,
      'rejection_reason': rejectionReason,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

