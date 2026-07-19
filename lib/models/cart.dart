import 'product.dart';
import 'kit.dart';

class CartItem {
  final int id;
  final dynamic item; // ProductVariant ou Kit
  final String itemType; // 'productvariant' ou 'kit'
  final int quantite;
  final double totalPrice;

  CartItem({
    required this.id,
    required this.item,
    required this.itemType,
    required this.quantite,
    required this.totalPrice,
  });

  String get nom {
    if (item is ProductVariant) {
      return (item as ProductVariant).desc;
    } else if (item is Kit) {
      return (item as Kit).nom;
    }
    return 'Article';
  }

  String get nomProduit {
    if (item is ProductVariant) {
      // Le nom complet n'est pas dans ProductVariant seul, on utilise desc
      return (item as ProductVariant).desc;
    } else if (item is Kit) {
      return (item as Kit).nom;
    }
    return 'Article';
  }

  String get prixUnitaire {
    if (item is ProductVariant) {
      return (item as ProductVariant).prixFinal;
    } else if (item is Kit) {
      return (item as Kit).prixFinal;
    }
    return '0';
  }

  String? get imageUrl {
    if (item is ProductVariant) {
      final v = item as ProductVariant;
      return v.images.isNotEmpty ? v.images.first.image : null;
    } else if (item is Kit) {
      return (item as Kit).image;
    }
    return null;
  }

  String get varianteInfo {
    if (item is ProductVariant) {
      final v = item as ProductVariant;
      final parts = <String>[];
      if (v.couleurNom != null) parts.add(v.couleurNom!);
      if (v.ram != null) parts.add(v.ram!);
      if (v.stockage != null) parts.add(v.stockage!);
      return parts.join(' · ');
    } else if (item is Kit) {
      final k = item as Kit;
      return '${k.items.length} article(s)';
    }
    return '';
  }

  int get stockDisponible {
    if (item is ProductVariant) {
      return (item as ProductVariant).stock;
    }
    return 99;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final itemData = json['item'] as Map<String, dynamic>?;
    dynamic parsedItem;
    String itemType = 'productvariant';

    if (itemData != null) {
      // Heuristique : un Kit a "nom" et "items", une variante a "sku"
      if (itemData.containsKey('sku') || itemData.containsKey('ram')) {
        parsedItem = ProductVariant.fromJson(itemData);
        itemType = 'productvariant';
      } else {
        parsedItem = Kit.fromJson(itemData);
        itemType = 'kit';
      }
    }

    return CartItem(
      id: json['id'],
      item: parsedItem,
      itemType: itemType,
      quantite: json['quantite'] ?? 1,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
    );
  }
}

class Cart {
  final int id;
  final List<CartItem> items;
  final int totalItems;
  final double totalPrice;

  Cart({
    required this.id,
    required this.items,
    required this.totalItems,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List? ?? [];
    return Cart(
      id: json['id'],
      items: itemsJson.map((i) => CartItem.fromJson(i)).toList(),
      totalItems: json['total_items'] ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
    );
  }

  Cart empty() => Cart(id: id, items: [], totalItems: 0, totalPrice: 0);
}
