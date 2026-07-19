import 'product.dart';

class KitItem {
  final int id;
  final ProductVariant variante;
  final int quantite;

  KitItem({
    required this.id,
    required this.variante,
    required this.quantite,
  });

  factory KitItem.fromJson(Map<String, dynamic> json) {
    return KitItem(
      id: json['id'],
      variante: ProductVariant.fromJson(json['variante']),
      quantite: json['quantite'] ?? 1,
    );
  }
}

class Kit {
  final int id;
  final String nom;
  final String description;
  final String? image;
  final String prixTotal;
  final String? prixPromo;
  final String prixFinal;
  final bool enPromotion;
  final String? promoValeur;
  final String? promoType;
  final String statut;
  final List<KitItem> items;

  Kit({
    required this.id,
    required this.nom,
    required this.description,
    this.image,
    required this.prixTotal,
    this.prixPromo,
    required this.prixFinal,
    required this.enPromotion,
    this.promoValeur,
    this.promoType,
    required this.statut,
    required this.items,
  });

  factory Kit.fromJson(Map<String, dynamic> json) {
    return Kit(
      id: json['id'],
      nom: json['nom'],
      description: json['description'] ?? '',
      image: json['image'],
      prixTotal: json['prix_total']?.toString() ?? json['prix_initial']?.toString() ?? '0',
      prixPromo: json['prix_promo']?.toString(),
      prixFinal: json['prix_final']?.toString() ?? '0',
      enPromotion: json['en_promotion'] ?? false,
      promoValeur: json['promo_valeur']?.toString(),
      promoType: json['promo_type']?.toString(),
      statut: json['statut'] ?? 'actif',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => KitItem.fromJson(i)).toList()
          : [],
    );
  }
}
