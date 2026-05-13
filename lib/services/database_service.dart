// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
 // Import important pour le Base64

// ... dans ta classe DatabaseService

Future<String> fileToBase64(File file) async {
  List<int> imageBytes = await file.readAsBytes();
  return base64Encode(imageBytes);
}

  Future<String> uploadFile(
    File file,
    String folder, {
    String? originalFileName,
  }) async {
    try {
      final String extension = _extractFileExtension(
        originalFileName ?? file.path,
      );
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}$extension';
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child(folder)
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child(fileName);

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'originalFileName': _extractBaseName(
              originalFileName ?? file.path,
            ),
          },
        ),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print("Erreur Upload: $e");
      throw Exception("Impossible d'envoyer le fichier");
    }
  }

  String _extractFileExtension(String pathOrName) {
    final String value = pathOrName.trim();
    final int dotIndex = value.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == value.length - 1) {
      return '';
    }
    return value.substring(dotIndex).toLowerCase();
  }

  String _extractBaseName(String pathOrName) {
    final String normalized = pathOrName.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  String _getContentType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<bool> checkDossierMedicalExists() async {
    try {
      final String uid = _auth.currentUser!.uid;
      final DocumentSnapshot doc =
          await _db.collection('Dossier_Medical').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveInitialMedicalData({
    required double poids,
    required double taille,
    required String groupeSanguin,
    String? nss,
  }) async {
    final String uid = _auth.currentUser!.uid;
    await _db.collection('Dossier_Medical').doc(uid).set({
      'uid': uid,
      'poids': poids,
      'taille': taille,
      'groupeSanguin': groupeSanguin,
      'nss': nss,
      'dateCreation': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteConsultation(String docId) async {
    try {
      final String uid = _auth.currentUser!.uid;

      final DocumentReference consultRef = _db
          .collection('Dossier_Medical')
          .doc(uid)
          .collection('Consultations')
          .doc(docId);

      final QuerySnapshot meds = await consultRef.collection('OrdonnanceInfo').get();
      for (final doc in meds.docs) {
        await doc.reference.delete();
      }

      final meds2 = await consultRef.collection('Medicaments').get();
      for (final doc in meds2.docs) {
        await doc.reference.delete();
      }

      final QuerySnapshot exams = await consultRef.collection('Examens').get();
      for (final doc in exams.docs) {
        await doc.reference.delete();
      }

      await consultRef.delete();

      // ignore: avoid_print
      print("Consultation supprimee avec succes");
    } catch (e) {
      // ignore: avoid_print
      print("Erreur lors de la suppression : $e");
    }
  }

// Dans database_service.dart
Future<void> saveFullConsultation({
  required Map<String, dynamic> consultData,
  required Map<String, dynamic> ordonnance,
  required List<Map<String, dynamic>> medicaments,
  required List<Map<String, dynamic>> examens,
  String? docId,
}) async {
  final String uid = _auth.currentUser!.uid;

  // A. Ordonnance — encode en Base64 seulement si une NOUVELLE photo est choisie
  if (ordonnance['file'] != null) {
    consultData['photoOrdonnanceBase64'] =
        await fileToBase64(ordonnance['file'] as File);
  }
  // ✅ Si pas de nouveau fichier en mode modif → la photo existante
  // est déjà dans consultData via consultationData passé au stepper
  // donc on ne l'écrase pas

  // B. Création ou mise à jour du document principal
  DocumentReference consultRef;
  if (docId != null && docId.isNotEmpty) {
    // ── Mode modification ──
    consultRef = _db
        .collection('Dossier_Medical')
        .doc(uid)
        .collection('Consultations')
        .doc(docId);
    await consultRef.update(consultData);

    // ✅ Supprime les anciennes sous-collections pour les remplacer
    final oldMeds = await consultRef.collection('Medicaments').get();
    for (var d in oldMeds.docs) await d.reference.delete();

    final oldExams = await consultRef.collection('Examens').get();
    for (var d in oldExams.docs) await d.reference.delete();
  } else {
    // ── Mode création ──
    consultData['timestamp'] = FieldValue.serverTimestamp();
    consultRef = await _db
        .collection('Dossier_Medical')
        .doc(uid)
        .collection('Consultations')
        .add(consultData);
  }

  // C. Sauvegarde des médicaments
  for (var med in medicaments) {
    if ((med['nom'] ?? '').isNotEmpty) {
      await consultRef.collection('Medicaments').add({
        'nom':       med['nom']       ?? '',
        'molecule':  med['molecule']  ?? '',
        'dosage':    med['dosage']    ?? '',
        'frequence': med['frequence'] ?? '',
        'duree':     med['duree']     ?? '',
      });
    }
  }

  // D. Sauvegarde des examens
  for (var ex in examens) {
    // ✅ Si nouvelle photo → encode, sinon garde l'ancienne
    String photoBase64 = ex['photoExamenBase64'] ?? '';
    if (ex['file'] != null) {
      photoBase64 = await fileToBase64(ex['file'] as File);
    }

    await consultRef.collection('Examens').add({
      'type':              ex['type'] ?? '',
      'date':              ex['date'] ?? '',
      'photoExamenBase64': photoBase64,
    });
  }
}
    // ✅ Récupère une consultation + ses sous-collections
    Future<Map<String, dynamic>> getConsultationDetail(String docId) async {
      final String uid = _auth.currentUser!.uid;

      final DocumentReference consultRef = _db
          .collection('Dossier_Medical')
          .doc(uid)
          .collection('Consultations')
          .doc(docId);

      // 1. Document principal
      final DocumentSnapshot doc = await consultRef.get();
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);

      // 2. Sous-collection Médicaments
      final QuerySnapshot meds =
          await consultRef.collection('Medicaments').get();
      data['medicaments'] =
          meds.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      // 3. Sous-collection Examens
      final QuerySnapshot exams =
          await consultRef.collection('Examens').get();
      data['examens'] =
          exams.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      return data;
    }
}
