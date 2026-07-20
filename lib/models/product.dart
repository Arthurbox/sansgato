class Category {
  final int id;
  final String nom;
  final String? code;
  final String layoutType;

  Category({required this.id, required this.nom, this.code, this.layoutType = 'portrait'});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nom: json['nom'],
      code: json['code'],
      layoutType: json['layout_type'] ?? 'portrait',
    );
  }
}

class ProductImage {
  final int id;
  final String image;

  ProductImage({required this.id, required this.image});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      image: json['image'],
    );
  }
}

class ProductVariant {
  final int id;
  final String prix;
  final String prixInitial;
  final String? prixPromo;
  final String prixFinal;
  final bool enPromotion;
  final String? promoValeur;
  final String? promoType;
  final int stock;
  final bool estDisponible;
  final String desc;
  final int? couleurId;
  final String? couleurNom;
  final String? couleurHex;
  final String? ram;
  final String? stockage;
  final String? sku;
  final String? tailleEcran;
  final String? resolution;
  final String? technologie;
  final List<ProductImage> images;
  String? productName;

  ProductVariant({
    required this.id,
    required this.prix,
    required this.prixInitial,
    this.prixPromo,
    required this.prixFinal,
    required this.enPromotion,
    this.promoValeur,
    this.promoType,
    required this.stock,
    required this.estDisponible,
    required this.desc,
    this.couleurId,
    this.couleurNom,
    this.couleurHex,
    this.ram,
    this.stockage,
    this.sku,
    this.tailleEcran,
    this.resolution,
    this.technologie,
    this.images = const [],
    this.productName,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    String generateDesc(Map<String, dynamic> j) {
      List<String> parts = [];
      if (j['couleur'] != null) parts.add(j['couleur']['nom']);
      if (j['stockage'] != null) parts.add(j['stockage'] is Map ? j['stockage']['capacite'] : j['stockage'].toString());
      if (j['ram'] != null) parts.add(j['ram'] is Map ? j['ram']['capacite'] : j['ram'].toString());
      return parts.join(' - ');
    }

    return ProductVariant(
      id: json['id'],
      prix: json['prix']?.toString() ?? '0',
      prixInitial: json['prix_initial']?.toString() ?? '0',
      prixPromo: json['prix_promo']?.toString(),
      prixFinal: json['prix_final']?.toString() ?? '0',
      enPromotion: json['en_promotion'] ?? false,
      promoValeur: json['promo_valeur']?.toString(),
      promoType: json['promo_type']?.toString(),
      stock: json['stock'] ?? 0,
      estDisponible: json['est_disponible'] ?? false,
      desc: generateDesc(json),
      couleurId: json['couleur'] != null ? json['couleur']['id'] : null,
      couleurNom: json['couleur'] != null ? json['couleur']['nom'] : null,
      couleurHex: json['couleur'] != null ? json['couleur']['code_hex'] : null,
      ram: json['ram']?.toString(),
      stockage: json['stockage']?.toString(),
      sku: json['sku']?.toString(),
      tailleEcran: json['taille_ecran']?.toString(),
      resolution: json['resolution']?.toString(),
      technologie: json['technologie']?.toString(),
      images: json['images'] != null
          ? (json['images'] as List).map((i) => ProductImage.fromJson(i)).toList()
          : [],
    );
  }
}

class Product {
  final int id;
  final String nomComplet;
  final String modele;
  final String? description;
  final String marque;
  final int? marqueId;
  final String etat;
  final Category? categorie;
  final List<ProductImage> images;
  final List<ProductVariant> variantes;
  final double noteMoyenne;
  final int avisCount;

  Product({
    required this.id,
    required this.nomComplet,
    required this.modele,
    this.description,
    required this.marque,
    this.marqueId,
    required this.etat,
    this.categorie,
    required this.images,
    required this.variantes,
    this.noteMoyenne = 0.0,
    this.avisCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nomComplet: json['nom_complet'] ?? '',
      modele: json['modele'] ?? '',
      description: json['description'],
      marque: (json['marque'] is Map) ? (json['marque']['nom'] ?? '') : (json['marque']?.toString() ?? ''),
      marqueId: (json['marque'] is Map) ? json['marque']['id'] : null,
      etat: json['etat'] ?? '',
      categorie: json['categorie'] != null ? Category.fromJson(json['categorie']) : null,
      images: json['images'] != null
          ? (json['images'] as List).map((i) => ProductImage.fromJson(i)).toList()
          : [],
      variantes: json['variantes'] != null
          ? (json['variantes'] as List).map((v) => ProductVariant.fromJson(v)).toList()
          : [],
      noteMoyenne: (json['note_moyenne'] ?? 0.0).toDouble(),
      avisCount: json['avis_count'] ?? 0,
    );
  }
}

class AvisClient {
  final int id;
  final String userName;
  final int note;
  final String commentaire;
  final String createdAt;

  AvisClient({
    required this.id,
    required this.userName,
    required this.note,
    required this.commentaire,
    required this.createdAt,
  });

  factory AvisClient.fromJson(Map<String, dynamic> json) {
    return AvisClient(
      id: json['id'],
      userName: json['user_name'] ?? 'Anonyme',
      note: json['note'],
      commentaire: json['commentaire'] ?? '',
      createdAt: json['created_at'],
    );
  }
}
