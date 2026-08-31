import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  int _userLoyaltyPoints = 250; // Initial loyalty points for customer
  double _appliedDiscount = 0.0;
  bool _pointsRedeemed = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get userLoyaltyPoints => _userLoyaltyPoints;
  double get appliedDiscount => _appliedDiscount;
  bool get pointsRedeemed => _pointsRedeemed;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get grandTotal {
    final total = subtotal - _appliedDiscount;
    return total < 0 ? 0.0 : total;
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _appliedDiscount = 0.0;
    _pointsRedeemed = false;
    notifyListeners();
  }

  bool redeemLoyaltyPoints() {
    if (_pointsRedeemed || _userLoyaltyPoints < 100) return false;

    // 100 points = 20 EGP discount (e.g., 250 points = 50 EGP discount)
    final discount = (_userLoyaltyPoints / 5).toDouble();
    _appliedDiscount = discount;
    _pointsRedeemed = true;
    _userLoyaltyPoints = 0;
    notifyListeners();
    return true;
  }

  void addEarnedPoints(double orderTotal) {
    // 10 points earned for every 100 EGP spent
    final earned = (orderTotal / 10).floor();
    _userLoyaltyPoints += earned;
    notifyListeners();
  }
}
