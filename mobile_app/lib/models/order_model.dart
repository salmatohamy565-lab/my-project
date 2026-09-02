import 'dart:convert';
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
  final String? customerAddress;
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
    this.customerAddress,
    this.rejectionReason,
    this.createdAt,
  });

  String get extractedAddress {
    if (customerAddress == null || customerAddress!.trim().isEmpty) return '';
    final str = customerAddress!.trim();
    if (str.contains('رقم التحويل:')) {
      final parts = str.split(RegExp(r'[•▪\-,|]?\s*رقم التحويل:'));
      var addr = parts.first.trim();
      if (addr.startsWith('العنوان:')) {
        addr = addr.replaceFirst('العنوان:', '').trim();
      }
      return addr.isNotEmpty ? addr : str;
    }
    if (str.startsWith('العنوان:')) {
      return str.replaceFirst('العنوان:', '').trim();
    }
    return str;
  }

  String get extractedTransferPhone {
    if (customerAddress != null && customerAddress!.contains('رقم التحويل:')) {
      final match = RegExp(r'رقم التحويل:\s*([0-9\+\s]+)').firstMatch(customerAddress!);
      if (match != null && match.group(1) != null) {
        final digits = match.group(1)!.trim();
        if (digits.isNotEmpty) return digits;
      }
    }
    if (customerPhone.isNotEmpty && customerPhone.trim().replaceAll(RegExp(r'[^\d]'), '').length >= 10) {
      return customerPhone.trim();
    }
    return '';
  }

  String get statusArabic {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_approval':
        return 'قيد الموافقة';
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
    final url = paymentProofUrl!.trim();
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:image') || url.contains('data:image')) {
      return url;
    }
    if (url.startsWith('proof_') || (!url.contains('/') && url.contains('.'))) {
      return 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/payment-proofs/$url';
    }
    String cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String cleanPath = url.startsWith('/') ? url : '/$url';
    return '$cleanBase$cleanPath';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawProducts = json['products'] ?? json['items_json'];
    List<dynamic> productListRaw = [];
    if (rawProducts is List) {
      productListRaw = rawProducts;
    } else if (rawProducts is String && rawProducts.trim().startsWith('[')) {
      try {
        productListRaw = jsonDecode(rawProducts);
      } catch (_) {}
    }

    List<ProductModel> prodList = productListRaw
        .whereType<Map<String, dynamic>>()
        .map((p) => ProductModel.fromJson(p))
        .toList();

    int parsedUserId = 0;
    if (json['user_id'] != null) {
      if (json['user_id'] is int) {
        parsedUserId = json['user_id'];
      } else {
        parsedUserId = int.tryParse(json['user_id'].toString()) ?? 0;
      }
    }

    String custName = json['user_name']?.toString() ?? json['customer_name']?.toString() ?? '';
    String custPhone = json['user_phone']?.toString() ?? json['customer_phone']?.toString() ?? json['sender_info']?.toString() ?? '';

    String? parsedProof = (json['payment_proof_url'] ??
            json['payment_proof'] ??
            json['payment_proof_filename'] ??
            json['proof_url'] ??
            json['receipt_url'] ??
            json['receipt'] ??
            json['payment_receipt'])
        ?.toString();

    String? parsedAddress = (json['customer_address'] ??
            json['address'] ??
            json['delivery_address'] ??
            json['location'])
        ?.toString();

    double parsedPrice = 0.0;
    if (json['total_price'] != null) {
      if (json['total_price'] is num) {
        parsedPrice = (json['total_price'] as num).toDouble();
      } else {
        parsedPrice = double.tryParse(json['total_price'].toString()) ?? 0.0;
      }
    } else if (json['total'] != null) {
      if (json['total'] is num) {
        parsedPrice = (json['total'] as num).toDouble();
      } else {
        parsedPrice = double.tryParse(json['total'].toString()) ?? 0.0;
      }
    }

    return OrderModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userId: parsedUserId,
      customerName: custName.isNotEmpty ? custName : 'عميل',
      customerPhone: custPhone,
      productIds: json['product_ids']?.toString() ?? '',
      itemsSummary: json['items_summary']?.toString() ?? '',
      products: prodList,
      status: json['status']?.toString() ?? 'pending',
      totalPrice: parsedPrice,
      paymentMethod: json['payment_method']?.toString(),
      paymentProofUrl: parsedProof,
      customerAddress: parsedAddress,
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
      'customer_address': customerAddress,
      'rejection_reason': rejectionReason,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

