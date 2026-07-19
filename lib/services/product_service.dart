import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/kit.dart';
import 'api_client.dart';

class ProductService {
  static Future<List<Product>> getProducts({String? search, int? categoryId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category'] = categoryId;

      final response = await ApiClient.instance.get(
        '/api/shop/products/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erreur réseau : ${e.message}');
      }
      throw Exception('Erreur : $e');
    }
  }

  static Future<Product> getProductDetail(int id) async {
    try {
      final response = await ApiClient.instance.get('/api/shop/products/$id/');
      return Product.fromJson(response.data);
    } catch (e) {
      throw Exception('Produit introuvable');
    }
  }

  static Future<List<Kit>> getKits() async {
    try {
      final response = await ApiClient.instance.get('/api/shop/kits/');
      final List<dynamic> data = response.data;
      return data.map((json) => Kit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur réseau : $e');
    }
  }

  static Future<Kit> getKitDetail(int id) async {
    try {
      final response = await ApiClient.instance.get('/api/shop/kits/$id/');
      return Kit.fromJson(response.data);
    } catch (e) {
      throw Exception('Kit introuvable');
    }
  }

  static Future<void> addToCart({required String contentType, required int objectId, int quantite = 1}) async {
    try {
      await ApiClient.instance.post(
        '/api/shop/cart/',
        data: {
          'content_type': contentType,
          'object_id': objectId,
          'quantite': quantite,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout au panier: $e');
    }
  }

  static Future<Map<String, dynamic>> getActivePromotions() async {
    try {
      final response = await ApiClient.instance.get('/api/shop/promotions/active/');
      final data = response.data;
      return {
        'products': (data['products'] as List).map((json) => Product.fromJson(json)).toList(),
        'kits': (data['kits'] as List).map((json) => Kit.fromJson(json)).toList(),
      };
    } catch (e) {
      throw Exception('Erreur réseau : $e');
    }
  }
}
