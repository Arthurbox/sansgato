import 'api_client.dart';
import '../config/api_config.dart';
import '../models/product.dart';

class CategoryService {
  static Future<List<Category>> getCategories() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.categories);
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur chargement catégories : $e');
    }
  }
}
