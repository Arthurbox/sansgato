import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/kit.dart';
import '../services/product_service.dart';

final productsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isNotEmpty) {
    return ProductService.getProducts(search: query);
  }
  return ProductService.getProducts();
});

final kitsProvider = FutureProvider<List<Kit>>((ref) async {
  return ProductService.getKits();
});

final activePromotionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ProductService.getActivePromotions();
});
