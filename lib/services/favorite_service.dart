import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_client.dart';
import '../models/product.dart';
import '../config/api_config.dart';

class FavoriteService {
  /// Retourne les IDs des produits favoris (pour le provider state)
  static Future<List<int>> fetchFavorites() async {
    final token = AuthService.accessToken;
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.favoritesIds}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<int>();
    } else {
      throw Exception('Failed to fetch favorites');
    }
  }

  /// Retourne les produits complets en favoris (pour la page Favoris)
  static Future<List<Product>> fetchFavoriteProducts() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.favorites);
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur favoris : $e');
    }
  }

  /// Ajoute ou retire un produit des favoris
  static Future<void> toggleFavorite(int productId) async {
    final token = AuthService.accessToken;
    if (token == null) throw Exception('Non authentifié - veuillez vous reconnecter');

    final url = '${AuthService.baseUrl}${ApiConfig.favoriteToggle(productId)}';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}
