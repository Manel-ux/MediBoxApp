// lib/models/dossier_medical_model.dart

class DossierMedicalModel {
  final String id;          // id_dossier (== id_patient dans Firestore)
  final DateTime? dateCreation;
  final String statut;      // 'Actif' | 'Archivé'
  final String idPatient;

  // Données vitales initiales (poids/taille/groupe sanguin)
  final double? poids;
  final double? taille;
  final String? groupeSanguin;
  final String? nss;

  DossierMedicalModel({
    required this.id,
    this.dateCreation,
    this.statut = 'Actif',
    required this.idPatient,
    this.poids,
    this.taille,
    this.groupeSanguin,
    this.nss,
  });

  factory DossierMedicalModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return DossierMedicalModel(
      id: id ?? map['id_dossier'] ?? '',
      dateCreation: map['date_creation']?.toDate(),
      statut: map['statut'] ?? 'Actif',
      idPatient: map['id_patient'] ?? map['uid'] ?? '',
      poids: (map['poids'] as num?)?.toDouble(),
      taille: (map['taille'] as num?)?.toDouble(),
      groupeSanguin: map['groupeSanguin'] ?? map['groupe_sanguin'],
      nss: map['nss'] ?? map['NSS'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id_patient': idPatient,
    'uid': idPatient,
    'date_creation': dateCreation,
    'statut': statut,
    'poids': poids,
    'taille': taille,
    'groupeSanguin': groupeSanguin,
    'nss': nss,
  };

  /// IMC calculé à la volée
  double? get imc {
    if (poids == null || taille == null || taille! == 0) return null;
    double tailleM = taille! / 100;
    return poids! / (tailleM * tailleM);
  }
}