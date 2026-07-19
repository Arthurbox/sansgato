class Promotion {
  final int id;
  final String contentTypeModel;
  final int objectId;
  final String cibleName;
  final String typeReduction;
  final double valeur;
  final DateTime dateDebut;
  final DateTime dateFin;
  final bool statut;

  Promotion({
    required this.id,
    required this.contentTypeModel,
    required this.objectId,
    required this.cibleName,
    required this.typeReduction,
    required this.valeur,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      contentTypeModel: json['content_type_model'] ?? '',
      objectId: json['object_id'],
      cibleName: json['cible_name'] ?? '',
      typeReduction: json['type_reduction'] ?? 'pourcentage',
      valeur: double.parse(json['valeur'].toString()),
      dateDebut: DateTime.parse(json['date_debut']),
      dateFin: DateTime.parse(json['date_fin']),
      statut: json['statut'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_type': contentTypeModel, // Will need specific content_type id when creating
      'object_id': objectId,
      'type_reduction': typeReduction,
      'valeur': valeur,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin.toIso8601String(),
      'statut': statut,
    };
  }
}
