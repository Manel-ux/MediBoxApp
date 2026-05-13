// lib/models/medicament_model.dart

/// Modèle de base — référentiel global des médicaments
class MedicamentModel {
  final String id;          // id_medicament
  final String nomCommercial;
  final String molecule;

  MedicamentModel({
    required this.id,
    required this.nomCommercial,
    this.molecule = '',
  });

  factory MedicamentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MedicamentModel(
      id: id ?? map['id_medicament'] ?? '',
      nomCommercial: map['nom_commercial'] ?? map['nom'] ?? '',
      molecule: map['molecule'] ?? map['molécule'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id_medicament': id,
    'nom_commercial': nomCommercial,
    'molecule': molecule,
  };
}


// ============================================================
// lib/models/contenu_ordonnance_model.dart
// ============================================================

/// Table de liaison Ordonnance ↔ Médicament avec détails de prescription
class ContenuOrdonnanceModel {
  final String idOrdonnance;
  final String idMedicament;
  final String dureeTraitement;   // ex: "7 jours", "1 mois"
  final String forme;             // ex: "Comprimé", "Sirop", "Injectable"
  final String dosage;            // ex: "500mg", "2 comprimés/j"

  // Données enrichies pour affichage
  final String? nomMedicament;
  final String? molecule;

  // Champs pour les rappels (étendus côté app, pas dans le MLD)
  final bool rappelActif;
  final int frequenceParJour;
  final List<String> heures;      // ex: ["08:00", "14:00", "20:00"]

  ContenuOrdonnanceModel({
    required this.idOrdonnance,
    required this.idMedicament,
    this.dureeTraitement = '',
    this.forme = '',
    this.dosage = '',
    this.nomMedicament,
    this.molecule,
    this.rappelActif = false,
    this.frequenceParJour = 1,
    this.heures = const [],
  });

  factory ContenuOrdonnanceModel.fromMap(Map<String, dynamic> map) {
    return ContenuOrdonnanceModel(
      idOrdonnance: map['id_ordonnance'] ?? '',
      idMedicament: map['id_medicament'] ?? '',
      dureeTraitement: map['duree_traitement'] ?? '',
      forme: map['forme'] ?? '',
      dosage: map['dosage'] ?? '',
      nomMedicament: map['nom_medicament'] ?? map['nom'] ?? map['nom_commercial'],
      molecule: map['molecule'],
      rappelActif: map['rappel_actif'] ?? false,
      frequenceParJour: map['frequence_par_jour'] ?? 1,
      heures: List<String>.from(map['heures'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'id_ordonnance': idOrdonnance,
    'id_medicament': idMedicament,
    'duree_traitement': dureeTraitement,
    'forme': forme,
    'dosage': dosage,
    'rappel_actif': rappelActif,
    'frequence_par_jour': frequenceParJour,
    'heures': heures,
  };

  ContenuOrdonnanceModel copyWith({
    bool? rappelActif,
    List<String>? heures,
    int? frequenceParJour,
  }) {
    return ContenuOrdonnanceModel(
      idOrdonnance: idOrdonnance,
      idMedicament: idMedicament,
      dureeTraitement: dureeTraitement,
      forme: forme,
      dosage: dosage,
      nomMedicament: nomMedicament,
      molecule: molecule,
      rappelActif: rappelActif ?? this.rappelActif,
      frequenceParJour: frequenceParJour ?? this.frequenceParJour,
      heures: heures ?? this.heures,
    );
  }
}