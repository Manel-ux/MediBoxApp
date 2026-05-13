// lib/models/examen_model.dart

import 'package:carnetdesante/models/medicament_model.dart';

class ExamenModel {
  final String id;            // id_examen
  final String typeExamen;    // ex: "Analyse de sang", "Radio", "IRM"
  final String dateExamen;
  final String compteRendu;
  final String idConsultation;

  // Champ étendu (non dans MLD, géré via Firebase Storage)
  final String urlFichier;
  final String fileName;

  ExamenModel({
    required this.id,
    required this.typeExamen,
    this.dateExamen = '',
    this.compteRendu = '',
    required this.idConsultation,
    this.urlFichier = '',
    this.fileName = '',
  });

  factory ExamenModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ExamenModel(
      id: id ?? map['id_examen'] ?? '',
      typeExamen: map['type_examen'] ?? map['type'] ?? '',
      dateExamen: map['date_examen'] ?? map['date'] ?? '',
      compteRendu: map['compte_rendu'] ?? map['resultat'] ?? '',
      idConsultation: map['id_consultation'] ?? '',
      urlFichier: map['urlFichier'] ?? '',
      fileName: map['fileName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id_examen': id,
    'type_examen': typeExamen,
    'date_examen': dateExamen,
    'compte_rendu': compteRendu,
    'id_consultation': idConsultation,
    'urlFichier': urlFichier,
    'fileName': fileName,
  };

  bool get aFichier => urlFichier.isNotEmpty;
}


// ============================================================
// lib/models/ordonnance_model.dart
// ============================================================

class OrdonnanceModel {
  final String id;              // id_ordonnance
  final String dateOrdonnance;
  final String photoOrdonnance; // URL Firebase Storage
  final String idConsultation;

  // Médicaments prescrits (table ContenuOrdonnance)
  final List<ContenuOrdonnanceModel> medicaments;

  OrdonnanceModel({
    required this.id,
    this.dateOrdonnance = '',
    this.photoOrdonnance = '',
    required this.idConsultation,
    this.medicaments = const [],
  });

  factory OrdonnanceModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return OrdonnanceModel(
      id: id ?? map['id_ordonnance'] ?? '',
      dateOrdonnance: map['date_ordonnance'] ?? '',
      photoOrdonnance: map['photo_ordonnance'] ?? '',
      idConsultation: map['id_consultation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id_ordonnance': id,
    'date_ordonnance': dateOrdonnance,
    'photo_ordonnance': photoOrdonnance,
    'id_consultation': idConsultation,
  };

  OrdonnanceModel copyWithMedicaments(List<ContenuOrdonnanceModel> meds) {
    return OrdonnanceModel(
      id: id,
      dateOrdonnance: dateOrdonnance,
      photoOrdonnance: photoOrdonnance,
      idConsultation: idConsultation,
      medicaments: meds,
    );
  }

  /// Médicaments avec rappel activé → source de l'écran Rappels
  List<ContenuOrdonnanceModel> get medicamentsAvecRappel =>
      medicaments.where((m) => m.rappelActif).toList();
}


// ============================================================
// lib/models/consultation_model.dart
// ============================================================

class ConsultationModel {
  final String id;              // id_consultation
  final String dateConsultation;
  final String motif;
  final String diagnostic;
  final String observations;
  final double? poids;
  final String? tension;
  final double? taille;
  final double? glycemie;
  final String idMedecin;
  final String idDossier;
  final DateTime? timestamp;

  // Données enrichies (chargées via jointures)
  final String? nomMedecin;
  final String? specialiteMedecin;
  final List<ExamenModel> examens;
  final OrdonnanceModel? ordonnance;

  ConsultationModel({
    required this.id,
    required this.dateConsultation,
    this.motif = '',
    this.diagnostic = '',
    this.observations = '',
    this.poids,
    this.tension,
    this.taille,
    this.glycemie,
    required this.idMedecin,
    required this.idDossier,
    this.timestamp,
    this.nomMedecin,
    this.specialiteMedecin,
    this.examens = const [],
    this.ordonnance,
  });

  factory ConsultationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ConsultationModel(
      id: id ?? map['id_consultation'] ?? '',
      dateConsultation: map['date_consultation'] ?? map['date'] ?? '',
      motif: map['motif'] ?? '',
      diagnostic: map['diagnostic'] ?? '',
      observations: map['observations'] ?? '',
      poids: (map['poids'] as num?)?.toDouble(),
      tension: map['tension'],
      taille: (map['taille'] as num?)?.toDouble(),
      glycemie: (map['glycemie'] as num?)?.toDouble(),
      idMedecin: map['id_medecin'] ?? '',
      idDossier: map['id_dossier'] ?? '',
      timestamp: map['timestamp']?.toDate(),
      nomMedecin: map['nom_medecin'],
      specialiteMedecin: map['specialite_medecin'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id_consultation': id,
    'date_consultation': dateConsultation,
    'motif': motif,
    'diagnostic': diagnostic,
    'observations': observations,
    'poids': poids,
    'tension': tension,
    'taille': taille,
    'glycemie': glycemie,
    'id_medecin': idMedecin,
    'id_dossier': idDossier,
    'timestamp': timestamp,
  };

  ConsultationModel copyWithDetails({
    List<ExamenModel>? examens,
    OrdonnanceModel? ordonnance,
    String? nomMedecin,
    String? specialiteMedecin,
  }) {
    return ConsultationModel(
      id: id,
      dateConsultation: dateConsultation,
      motif: motif,
      diagnostic: diagnostic,
      observations: observations,
      poids: poids,
      tension: tension,
      taille: taille,
      glycemie: glycemie,
      idMedecin: idMedecin,
      idDossier: idDossier,
      timestamp: timestamp,
      nomMedecin: nomMedecin ?? this.nomMedecin,
      specialiteMedecin: specialiteMedecin ?? this.specialiteMedecin,
      examens: examens ?? this.examens,
      ordonnance: ordonnance ?? this.ordonnance,
    );
  }

  String get titre => motif.isNotEmpty ? motif : 'Consultation du $dateConsultation';
}


// Import nécessaire dans ordonnance_model.dart et consultation_model.dart :
// import 'medicament_model.dart';   (pour ContenuOrdonnanceModel)
// import 'examen_model.dart';
// import 'ordonnance_model.dart';