import 'package:carnetdesante/services/referentiel_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InitReferentiel {
  static final _db = FirebaseFirestore.instance;

  /// ✅ À appeler UNE SEULE FOIS depuis main.dart ou depuis un bouton admin
  /// Vérifie si les collections sont vides avant d'insérer
  static Future<void> initialiserSiVide() async {
    debugPrint('🔄 Vérification des collections référentielles...');

    await _initCollection(
      collection: 'AllergiesRef',
      checkField: 'nomAllergie',
      data: ReferentielService.allergiesPredefines
          .map((s) => {'nomAllergie': s})
          .toList(),
    );

    await _initCollection(
      collection: 'MaladiesRef',
      checkField: 'nomMaladie',
      data: ReferentielService.maladiesPredefines
          .map((s) => {'nomMaladie': s})
          .toList(),
    );

    await _initCollection(
      collection: 'TypesExamen',
      checkField: 'type',
      data: ReferentielService.typesExamenPredefines
          .map((s) => {'type': s})
          .toList(),
    );

    await _initCollection(
      collection: 'Medicaments',
      checkField: 'nom',
      data: ReferentielService.medicamentsPredefinis
          .map((m) => {
                'nom': m['nom'] ?? '',
                'molecule': m['molecule'] ?? '',
                'dosage': m['dosage'] ?? '',
              })
          .toList(),
    );

    debugPrint('✅ Collections référentielles initialisées');
  }

  static Future<void> _initCollection({
    required String collection,
    required String checkField,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      // ✅ Vérifie si la collection est déjà remplie
      final snap = await _db
          .collection(collection)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snap.docs.isNotEmpty) {
        debugPrint('⏭️ $collection déjà initialisée, skip');
        return;
      }

      debugPrint('📝 Initialisation de $collection (${data.length} entrées)...');

      // ✅ Batch write pour performances
      const int batchSize = 500;
      for (int i = 0; i < data.length; i += batchSize) {
        final batch = _db.batch();
        final chunk = data.skip(i).take(batchSize);
        for (final item in chunk) {
          final ref = _db.collection(collection).doc();
          batch.set(ref, {
            ...item,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      debugPrint('✅ $collection initialisée');
    } catch (e) {
      debugPrint('❌ Erreur init $collection : $e');
    }
  }
}