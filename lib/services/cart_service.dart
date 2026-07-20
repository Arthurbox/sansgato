import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/cart.dart';
import '../config/api_config.dart';

class CartService {
  static String get baseUrl => AuthService.baseUrl;

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Charger le panier de l'utilisateur connecté
  static Future<Cart> getCart() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.cart}'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Cart.fromJson(data);
    }
    throw Exception('Impossible de charger le panier.');
  }

  /// Ajouter un article au panier
  /// [contentType] : 'productvariant' ou 'kit'
  /// [objectId]    : ID de la variante ou du kit
  static Future<Cart> addItem({
    required String contentType,
    required int objectId,
    int quantite = 1,
  }) async {
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.cart}'),
      headers: _headers,
      body: jsonEncode({
        'content_type': contentType,
        'object_id': objectId,
        'quantite': quantite,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Cart.fromJson(data);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['detail'] ?? 'Erreur lors de l\'ajout au panier.');
  }

  /// Modifier la quantité d'un article
  static Future<Cart> updateQuantity({
    required int cartItemId,
    required int quantite,
  }) async {
    final response = await http.patch(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.cartItem(cartItemId)}'),
      headers: _headers,
      body: jsonEncode({'quantite': quantite}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Cart.fromJson(data);
    }
    throw Exception('Impossible de modifier la quantité.');
  }

  /// Supprimer un article du panier
  static Future<Cart> removeItem(int cartItemId) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.cartItem(cartItemId)}'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Cart.fromJson(data);
    }
    throw Exception('Impossible de supprimer l\'article.');
  }

  /// Passer à la caisse (Validation de commande)
  static Future<void> checkout(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}${ApiConfig.checkout}'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Erreur lors de la validation de la commande.');
    }
  }
}
