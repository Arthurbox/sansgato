import 'package:flutter_test/flutter_test.dart';
import 'package:sansgato/models/product.dart';

void main() {
  group('Product Models Unit Tests', () {
    test('Category.fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'nom': 'Electronique',
        'code': 'ELEC',
        'layout_type': 'grid'
      };
      final category = Category.fromJson(json);

      expect(category.id, 1);
      expect(category.nom, 'Electronique');
      expect(category.code, 'ELEC');
      expect(category.layoutType, 'grid');
    });

    test('Category.fromJson should use default layout_type if missing', () {
      final json = {
        'id': 2,
        'nom': 'Vêtements',
      };
      final category = Category.fromJson(json);

      expect(category.layoutType, 'portrait');
    });

    test('ProductImage.fromJson should parse correctly', () {
      final json = {
        'id': 10,
        'image': 'https://example.com/image.png'
      };
      final image = ProductImage.fromJson(json);

      expect(image.id, 10);
      expect(image.image, 'https://example.com/image.png');
    });
  });
}
