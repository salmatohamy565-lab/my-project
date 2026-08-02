import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ProductModel> _products = [];
  List<ProductModel> _publicProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<ProductModel> get publicProducts => _publicProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getProducts();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _products = data.map((json) => ProductModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  static final List<ProductModel> _defaultProducts = [
    ProductModel(
      id: 1,
      name: 'لوحة إعلانية كلادينج + فلكس',
      description: 'تصميم وتنفيذ لوحات المحلات والشركات باحترافية عالية وبخامات مقاومة للعوامل الجوية مع إضاءة LED.',
      price: 1500.0,
    ),
    ProductModel(
      id: 2,
      name: 'كروت شخصية VIP باصم وفلو',
      description: 'تصميم وطباعة كروت شخصية فاخرة كوشيه 350 جرام مع سلفان مات وبصمة حرارية ذهبية أو فضية.',
      price: 250.0,
    ),
    ProductModel(
      id: 3,
      name: 'تصميم هوية بصرية متكاملة',
      description: 'شعار متكامل (Logo)، كروت شخصية، أوراق رسمية، فولديرات، ودليل استخدام الألوان والخطوط.',
      price: 3500.0,
    ),
    ProductModel(
      id: 4,
      name: 'بروشورات وفلايرات دعاية',
      description: 'تصميم مطبوعات دعاية وإعلان بألوان جذابة وتسليم جاهز للطباعة عالية الدقة بأسرع وقت.',
      price: 450.0,
    ),
    ProductModel(
      id: 5,
      name: 'تصميم إعلانات ممولة سوشيال ميديا',
      description: 'تصاميم احترافية متوافقة مع جميع المنصات (فيسبوك، انستجرام، وتيك توك) لزيادة التفاعل والمبيعات.',
      price: 300.0,
    ),
  ];

  Future<void> fetchPublicProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getPublicProducts();
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          _publicProducts = data.map((json) => ProductModel.fromJson(json)).toList();
        } else {
          _publicProducts = List.from(_defaultProducts);
        }
      } else {
        _publicProducts = List.from(_defaultProducts);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _publicProducts = List.from(_defaultProducts);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(String name, String description, double price, File? imageFile, {String? categoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createProduct(name, description, price, imageFile, categoryId: categoryId);
      if (response.statusCode == 201) {
        _isLoading = false;
        await fetchProducts();
        await fetchPublicProducts();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> editProduct(int productId, String name, String description, double price, File? imageFile, {String? categoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProduct(productId, name, description, price, imageFile, categoryId: categoryId);
      if (response.statusCode == 200) {
        _isLoading = false;
        await fetchProducts();
        await fetchPublicProducts();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteProduct(productId);
      if (response.statusCode == 200) {
        _isLoading = false;
        await fetchProducts();
        await fetchPublicProducts();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
