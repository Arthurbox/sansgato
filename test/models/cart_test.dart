import 'package:flutter_test/flutter_test.dart';
import 'package:sansgato/models/cart.dart';
import 'package:sansgato/models/product.dart';

void main() {
  group('CartItem Unit Tests', () {
    // Helper to create a dummy variant
    ProductVariant createDummyVariant() {
      return ProductVariant(
        id: 1,
        prix: '1000',
        prixInitial: '1000',
        prixFinal: '800',
        enPromotion: true,
        stock: 10,
        estDisponible: true,
        desc: 'Dummy Variant',
        images: [],
      );
    }

    test('CartItem getters should work correctly for ProductVariant', () {
      final variant = createDummyVariant();
      final item = CartItem(
        id: 1,
        item: variant,
        itemType: 'productvariant',
        quantite: 2,
        totalPrice: 1600.0,
      );

      expect(item.nom, 'Dummy Variant');
      expect(item.nomProduit, 'Dummy Variant');
      expect(item.prixUnitaire, '800');
    });

    test('CartItem imageUrl should return null if no images', () {
      final variant = createDummyVariant();
      final item = CartItem(
        id: 1,
        item: variant,
        itemType: 'productvariant',
        quantite: 1,
        totalPrice: 800.0,
      );

      expect(item.imageUrl, isNull);
    });

    test('CartItem imageUrl should return first image url if images exist', () {
      final variant = ProductVariant(
        id: 1,
        prix: '1000',
        prixInitial: '1000',
        prixFinal: '1000',
        enPromotion: false,
        stock: 10,
        estDisponible: true,
        desc: 'Dummy Variant',
        images: [ProductImage(id: 1, image: 'url1'), ProductImage(id: 2, image: 'url2')],
      );
      final item = CartItem(
        id: 1,
        item: variant,
        itemType: 'productvariant',
        quantite: 1,
        totalPrice: 1000.0,
      );

      expect(item.imageUrl, 'url1');
    });
  });
}
