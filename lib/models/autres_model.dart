// lib/models/notification_model.dart

import 'package:carnetdesante/models/medicament_model.dart';

/// Correspond à la table Notification du MLD
/// Liée à un RDV OU à un médicament (l'un ou l'autre peut être null)
class NotificationModel {
  final String id;              // id_notification
  final String heureNotification; // ex: "08:00"
  final String? idRdv;
  final String? idMedicament;

  // Données enrichies pour affichage
  final String? titreAffichage;       // "Rappel médicament" ou "Rendez-vous"
  final String? descriptionAffichage; // nom du médicament ou motif du RDV
  final DateTime? dateComplete;       // pour les RDV (date + heure)

  NotificationModel({
    required this.id,
    required this.heureNotification,
    this.idRdv,
    this.idMedicament,
    this.titreAffichage,
    this.descriptionAffichage,
    this.dateComplete,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return NotificationModel(
      id: id ?? map['id_notification'] ?? '',
      heureNotification: map['heure_notification'] ?? '',
      idRdv: map['id_rdv'],
      idMedicament: map['id_medicament'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id_notification': id,
    'heure_notification': heureNotification,
    'id_rdv': idRdv,
    'id_medicament': idMedicament,
  };

  bool get estPourMedicament => idMedicament != null;
  bool get estPourRdv => idRdv != null;
}


// ============================================================
// lib/models/maladie_chronique_model.dart
// ============================================================

class MaladieChronniqueModel {
  final String id;            // id_maladie
  final String nomMaladie;
  final String description;

  // Médicaments associés (table Traitement_Associe)
  final List<String> idsMedicaments;

  MaladieChronniqueModel({
    required this.id,
    required this.nomMaladie,
    this.description = '',
    this.idsMedicaments = const [],
  });

  factory MaladieChronniqueModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MaladieChronniqueModel(
      id: id ?? map['id_maladie'] ?? '',
      nomMaladie: map['nom_maladie'] ?? '',
      description: map['description'] ?? '',
      idsMedicaments: List<String>.from(map['ids_medicaments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'id_maladie': id,
    'nom_maladie': nomMaladie,
    'description': description,
  };
}


// ============================================================
// lib/models/allergie_model.dart
// ============================================================

class AllergieModel {
  final String id;            // id_allergie
  final String nomAllergie;

  // Observation spécifique au patient (table Avoir_Allergie)
  final String? observation;

  AllergieModel({
    required this.id,
    required this.nomAllergie,
    this.observation,
  });

  factory AllergieModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AllergieModel(
      id: id ?? map['id_allergie'] ?? '',
      nomAllergie: map['nom_allergie'] ?? '',
      observation: map['obs'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id_allergie': id,
    'nom_allergie': nomAllergie,
    'obs': observation,
  };
}


// ============================================================
// lib/models/hospitalisation_model.dart
// ============================================================

class HospitalisationModel {
  final String id;            // id_hospitalisation
  final String dateEntree;
  final String? dateSortie;
  final String hopital;
  final String service;
  final String motif;
  final String idDossier;

  HospitalisationModel({
    required this.id,
    required this.dateEntree,
    this.dateSortie,
    required this.hopital,
    this.service = '',
    this.motif = '',
    required this.idDossier,
  });

  factory HospitalisationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return HospitalisationModel(
      id: id ?? map['id_hospitalisation'] ?? '',
      dateEntree: map['date_entrée'] ?? map['date_entree'] ?? '',
      dateSortie: map['date_sortie'],
      hopital: map['hopital'] ?? '',
      service: map['service'] ?? '',
      motif: map['motif'] ?? '',
      idDossier: map['id_dossier'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id_hospitalisation': id,
    'date_entrée': dateEntree,
    'date_sortie': dateSortie,
    'hopital': hopital,
    'service': service,
    'motif': motif,
    'id_dossier': idDossier,
  };

  bool get enCours => dateSortie == null || dateSortie!.isEmpty;
}


// ============================================================
// lib/models/historique_mensuration_model.dart
// ============================================================

/// Suivi longitudinal des constantes vitales du patient
class HistoriqueMensurationModel {
  final String id;            // id_historique
  final DateTime dateHistorique;
  final double? poids;
  final String? tension;
  final double? taille;
  final double? glycemie;
  final String idPatient;

  HistoriqueMensurationModel({
    required this.id,
    required this.dateHistorique,
    this.poids,
    this.tension,
    this.taille,
    this.glycemie,
    required this.idPatient,
  });

  factory HistoriqueMensurationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return HistoriqueMensurationModel(
      id: id ?? map['id_historique'] ?? '',
      dateHistorique: map['date_historique']?.toDate() ?? DateTime.now(),
      poids: (map['poids'] as num?)?.toDouble(),
      tension: map['tension'],
      taille: (map['taille'] as num?)?.toDouble(),
      glycemie: (map['glycemie'] as num?)?.toDouble(),
      idPatient: map['id_patient'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id_historique': id,
    'date_historique': dateHistorique,
    'poids': poids,
    'tension': tension,
    'taille': taille,
    'glycemie': glycemie,
    'id_patient': idPatient,
  };

  double? get imc {
    if (poids == null || taille == null || taille! == 0) return null;
    double tailleM = taille! / 100;
    return poids! / (tailleM * tailleM);
  }
}


// ============================================================
// lib/models/rappel_model.dart  (modèle dérivé — pas de table Firestore)
// ============================================================
// Construit côté app depuis ContenuOrdonnanceModel (rappelActif == true)
// Utilisé uniquement pour l'affichage dans l'écran Rappels

class RappelModel {
  final String idMedicament;
  final String idOrdonnance;
  final String idConsultation;
  final String nomMedicament;
  final String dosage;
  final String forme;
  final String dureeTraitement;
  final List<String> heures;
  final int frequenceParJour;

  RappelModel({
    required this.idMedicament,
    required this.idOrdonnance,
    required this.idConsultation,
    required this.nomMedicament,
    this.dosage = '',
    this.forme = '',
    this.dureeTraitement = '',
    required this.heures,
    required this.frequenceParJour,
  });

  /// Construit depuis un ContenuOrdonnanceModel
  factory RappelModel.fromContenuOrdonnance(
    ContenuOrdonnanceModel contenu, {
    required String idConsultation,
  }) {
    return RappelModel(
      idMedicament: contenu.idMedicament,
      idOrdonnance: contenu.idOrdonnance,
      idConsultation: idConsultation,
      nomMedicament: contenu.nomMedicament ?? contenu.idMedicament,
      dosage: contenu.dosage,
      forme: contenu.forme,
      dureeTraitement: contenu.dureeTraitement,
      heures: contenu.heures,
      frequenceParJour: contenu.frequenceParJour,
    );
  }

  String get prochainRappel {
    if (heures.isEmpty) return 'Heure non définie';
    final now = DateTime.now();
    final nowStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    for (final h in heures) {
      if (h.compareTo(nowStr) > 0) return h;
    }
    return heures.first; // demain
  }
}

// Note d'import pour rappel_model.dart :
// import 'medicament_model.dart'; (pour ContenuOrdonnanceModel)