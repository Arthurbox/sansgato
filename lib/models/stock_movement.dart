class StockMovement {
  final int id;
  final int varianteId;
  final String varianteNom;
  final int quantite;
  final String typeMouvement;
  final String motif;
  final DateTime date;

  StockMovement({
    required this.id,
    required this.varianteId,
    required this.varianteNom,
    required this.quantite,
    required this.typeMouvement,
    required this.motif,
    required this.date,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'],
      varianteId: json['variante'],
      varianteNom: json['variante_nom'] ?? 'Variante inconnue',
      quantite: json['quantite'],
      typeMouvement: json['type_mouvement'],
      motif: json['motif'],
      date: DateTime.parse(json['date']),
    );
  }
}
