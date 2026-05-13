import 'package:cloud_firestore/cloud_firestore.dart';

class ReferentielService {
  static final _db = FirebaseFirestore.instance;

  // ── Médecin ───────────────────────────────────────────
  static Future<void> sauvegarderMedecin({
    required String nom,
    required String prenom,
    String specialite = '',
    String tel = '',
    String adresse = '',
  }) async {
    if (nom.trim().isEmpty && prenom.trim().isEmpty) return;
    final nomComplet = '$prenom $nom'.trim();

    // Vérifie si existe déjà
    final exist = await _db
        .collection('Medecins')
        .where('nomComplet', isEqualTo: nomComplet)
        .limit(1)
        .get();
    if (exist.docs.isNotEmpty) {
      // Met à jour les infos si manquantes
      await exist.docs.first.reference.update({
        if (specialite.isNotEmpty) 'specialite': specialite,
        if (tel.isNotEmpty) 'tel': tel,
        if (adresse.isNotEmpty) 'adresse': adresse,
      });
      return;
    }

    await _db.collection('Medecins').add({
      'nom':        nom.trim(),
      'prenom':     prenom.trim(),
      'nomComplet': nomComplet,
      'specialite': specialite.trim(),
      'tel':        tel.trim(),
      'adresse':    adresse.trim(),
      'createdAt':  FieldValue.serverTimestamp(),
    });
  }

  // ── Médicament ────────────────────────────────────────
  static Future<void> sauvegarderMedicament({
    required String nom,
    String molecule = '',
    String dosage = '',
  }) async {
    if (nom.trim().isEmpty) return;

    final exist = await _db
        .collection('Medicaments')
        .where('nom', isEqualTo: nom.trim())
        .limit(1)
        .get();
    if (exist.docs.isNotEmpty) return;

    await _db.collection('Medicaments').add({
      'nom':       nom.trim(),
      'molecule':  molecule.trim(),
      'dosage':    dosage.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Type d'examen ─────────────────────────────────────
  static Future<void> sauvegarderTypeExamen(String type) async {
    if (type.trim().isEmpty) return;

    final exist = await _db
        .collection('TypesExamen')
        .where('type', isEqualTo: type.trim())
        .limit(1)
        .get();
    if (exist.docs.isNotEmpty) return;

    await _db.collection('TypesExamen').add({
      'type':      type.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Maladie chronique ─────────────────────────────────
  static Future<void> sauvegarderMaladie(String nom) async {
    if (nom.trim().isEmpty) return;

    final exist = await _db
        .collection('MaladiesRef')
        .where('nomMaladie', isEqualTo: nom.trim())
        .limit(1)
        .get();
    if (exist.docs.isNotEmpty) return;

    await _db.collection('MaladiesRef').add({
      'nomMaladie': nom.trim(),
      'createdAt':  FieldValue.serverTimestamp(),
    });
  }

  // ── Allergie ──────────────────────────────────────────
  static Future<void> sauvegarderAllergie(String nom) async {
    if (nom.trim().isEmpty) return;

    final exist = await _db
        .collection('AllergiesRef')
        .where('nomAllergie', isEqualTo: nom.trim())
        .limit(1)
        .get();
    if (exist.docs.isNotEmpty) return;

    await _db.collection('AllergiesRef').add({
      'nomAllergie': nom.trim(),
      'createdAt':   FieldValue.serverTimestamp(),
    });
  }
}