import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';
import 'firebase_storage_service.dart';
import '../models/product.dart';

class AdminApiService {
  static String get baseUrl => AuthService.baseUrl;

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- CATALOGUE : Categories, Couleurs, RAM, Stockages ---
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/shop/admin/categories/'), headers: _headers);
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur de chargement des catégories');
  }

  static Future<Map<String, dynamic>> createCategory(String nom) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/categories/'),
      headers: _headers,
      body: jsonEncode({'nom': nom}),
    );
    if (response.statusCode == 201) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur de création de la catégorie');
  }

  static Future<List<dynamic>> getColors() async {
    final response = await http.get(Uri.parse('$baseUrl/api/shop/admin/colors/'), headers: _headers);
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur de chargement des couleurs');
  }

  static Future<List<dynamic>> getBrands({int? categoryId}) async {
    String url = '$baseUrl/api/shop/admin/brands/';
    if (categoryId != null) {
      url += '?category=$categoryId';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur de chargement des marques');
  }

  static Future<Map<String, dynamic>> createBrand(String nom, int categoryId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/brands/'),
      headers: _headers,
      body: jsonEncode({
        'nom': nom,
        'categories': [categoryId]
      }),
    );
    if (response.statusCode == 201) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la création de la marque: ${response.body}');
  }

  // --- PRODUITS ---
  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/products/'),
      headers: _headers,
      body: jsonEncode(productData),
    );
    if (response.statusCode == 201) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la création du produit: ${response.body}');
  }

  static Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> productData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/shop/admin/products/$id/'),
      headers: _headers,
      body: jsonEncode(productData),
    );
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la modification du produit: ${response.body}');
  }

  static Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/shop/admin/products/$id/'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      try {
        final body = json.decode(response.body);
        throw Exception(body['detail'] ?? 'Erreur lors de la suppression du produit');
      } catch (e) {
        if (e is FormatException) throw Exception('Erreur serveur: Impossible de supprimer le produit');
        rethrow;
      }
    }
  }

  static Future<Map<String, dynamic>> uploadVariantImage(int variantId, XFile imageFile) async {
    // 1. Uploader sur Firebase Storage
    final String imageUrl = await FirebaseStorageService.uploadImage(imageFile, 'products');

    // 2. Envoyer l'URL à Django
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/variants/$variantId/upload_image/'),
      headers: _headers,
      body: jsonEncode({'image_url': imageUrl}),
    );
    
    if (response.statusCode == 201) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Erreur lors de l\'enregistrement de l\'image du produit: ${response.body}');
  }

  // --- VARIANTES ---
  static Future<Map<String, dynamic>> createProductVariant(Map<String, dynamic> variantData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/variants/'),
      headers: _headers,
      body: jsonEncode(variantData),
    );
    if (response.statusCode == 201) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la création de la variante: ${response.body}');
  }

  static Future<Map<String, dynamic>> updateProductVariant(int id, Map<String, dynamic> variantData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/shop/admin/variants/$id/'),
      headers: _headers,
      body: jsonEncode(variantData),
    );
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la modification de la variante: ${response.body}');
  }

  static Future<void> deleteProductVariant(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/shop/admin/variants/$id/'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      try {
        final body = json.decode(response.body);
        throw Exception(body['detail'] ?? 'Erreur lors de la suppression de la variante');
      } catch (e) {
        if (e is FormatException) throw Exception('Erreur serveur: Impossible de supprimer la variante');
        rethrow;
      }
    }
  }

  // --- KITS ---
  static Future<Map<String, dynamic>> createKit(Map<String, dynamic> kitData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/kits/'),
      headers: _headers,
      body: jsonEncode(kitData),
    );
    if (response.statusCode == 201) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la création du kit: ${response.body}');
  }

  static Future<Map<String, dynamic>> uploadKitImage(int kitId, XFile imageFile) async {
    // 1. Uploader sur Firebase Storage
    final String imageUrl = await FirebaseStorageService.uploadImage(imageFile, 'kits');

    // 2. Envoyer l'URL à Django
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/kits/$kitId/upload_image/'),
      headers: _headers,
      body: jsonEncode({'image_url': imageUrl}),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Erreur lors de l\'enregistrement de l\'image du kit: ${response.body}');
  }

  static Future<Map<String, dynamic>> addKitItem(int kitId, int varianteId, int quantite) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/kits/$kitId/add_item/'),
      headers: _headers,
      body: jsonEncode({
        'variante': varianteId,
        'quantite': quantite,
      }),
    );
    if (response.statusCode == 201) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de l\'ajout de l\'article au kit: ${response.body}');
  }

  static Future<void> removeKitItem(int kitId, int varianteId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/kits/$kitId/remove_item/'),
      headers: _headers,
      body: jsonEncode({'variante': varianteId}),
    );
    if (response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression de l\'article du kit: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateKit(int id, Map<String, dynamic> kitData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/shop/admin/kits/$id/'),
      headers: _headers,
      body: jsonEncode(kitData),
    );
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la mise à jour du kit: ${response.body}');
  }

  static Future<void> deleteKit(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/shop/admin/kits/$id/'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression du kit: ${response.body}');
    }
  }

  // --- PROMOTIONS ---
  static Future<List<dynamic>> getPromotions() async {
    final response = await http.get(Uri.parse('$baseUrl/api/shop/admin/promotions/'), headers: _headers);
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur de chargement des promotions');
  }

  static Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> promoData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/shop/admin/promotions/'),
      headers: _headers,
      body: jsonEncode(promoData),
    );
    if (response.statusCode == 201) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la création de la promotion: ${response.body}');
  }

  static Future<Map<String, dynamic>> updatePromotion(int id, Map<String, dynamic> promoData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/shop/admin/promotions/$id/'),
      headers: _headers,
      body: jsonEncode(promoData),
    );
    if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
    throw Exception('Erreur lors de la mise à jour de la promotion: ${response.body}');
  }

  static Future<void> deletePromotion(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/shop/admin/promotions/$id/'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression de la promotion: ${response.body}');
    }
  }

  // --- MISSING METHODS ---
  static Future<List<dynamic>> getExpenses() async => [];
  static Future<Map<String, dynamic>> getDashboardOverview() async => {};
  static Future<Map<String, dynamic>> getFinanceReport({int? year, int? month}) async => {};
  static Future<List<dynamic>> getEmployees() async => [];
  static Future<List<dynamic>> getExpenseCategories() async => [];
  static Future<void> updateEmployee(dynamic id, dynamic data) async {}
  static Future<void> createEmployee(dynamic data) async {}
  static Future<void> deleteEmployee(dynamic id) async {}
  static Future<void> addExpense([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e]) async {}
  static Future<void> updateExpense(dynamic id, dynamic data) async {}
  static Future<void> deleteExpense(dynamic id) async {}
  static Future<Map<String, dynamic>> getDashboardFiltered({dynamic year, dynamic month, dynamic day}) async => {};
  static Future<List<Product>> getProducts() async => [];
  static Future<void> adjustStock(dynamic productId, dynamic variantId, dynamic newStock) async {}
}
