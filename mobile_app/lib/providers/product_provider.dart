import 'dart:io';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<ProductModel> _publicProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  List<ProductModel> get publicProducts => _publicProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    try {
      final rawCategories = await _apiService.getCategoriesFromSupabase();
      _categories = rawCategories.map((cJson) {
        final List<dynamic> rawSubs = cJson['subcategories'] ?? [];
        final subcats = rawSubs.map((sJson) => SubcategoryModel.fromJson(sJson)).toList();
        return CategoryModel.fromSupabase(cJson, subcats: subcats);
      }).toList();
      notifyListeners();
    } catch (e) {
      print('[PRODUCT PROVIDER] Error fetching categories: $e');
    }
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await fetchCategories();
      final response = await _apiService.getProducts();
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        _products = data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        _products = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _products = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPublicProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getPublicProducts();
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        _publicProducts = data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        _publicProducts = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _publicProducts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(
    String name,
    String description,
    double price,
    File? imageFile, {
    int? categoryId,
    int? subcategoryId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createProduct(
        name,
        description,
        price,
        imageFile,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
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

  Future<bool> editProduct(
    int productId,
    String name,
    String description,
    double price,
    File? imageFile, {
    int? categoryId,
    int? subcategoryId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProduct(
        productId,
        name,
        description,
        price,
        imageFile,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
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
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
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
