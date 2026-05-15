import 'package:cloud_firestore/cloud_firestore.dart';

class ReferentielService {
  static final _db = FirebaseFirestore.instance;

  static const List<String> allergiesPredefines = [
    'Pénicilline', 'Aspirine', 'Ibuprofène', 'Amoxicilline',
    'Sulfamides', 'Codéine', 'Morphine', 'Tétracyclines',
    'Latex', 'Arachides', 'Fruits à coque', 'Lait de vache',
    'Œufs', 'Gluten', 'Fruits de mer', 'Soja',
    'Pollen', 'Acariens', 'Poils d\'animaux', 'Moisissures',
    'Nickel', 'Parfums', 'Colorants', 'Conservateurs',
    'Venin d\'abeille', 'Venin de guêpe', 'Iode',
  ];

  static const List<String> maladiesPredefines = [
    'Diabète type 1', 'Diabète type 2', 'Hypertension artérielle',
    'Asthme', 'Bronchite chronique', 'BPCO',
    'Insuffisance cardiaque', 'Coronaropathie', 'Arythmie',
    'Hypothyroïdie', 'Hyperthyroïdie', 'Insuffisance rénale chronique',
    'Insuffisance hépatique', 'Cirrhose', 'Hépatite chronique',
    'Arthrose', 'Polyarthrite rhumatoïde', 'Lupus',
    'Épilepsie', 'Maladie de Parkinson', 'Sclérose en plaques',
    'Dépression chronique', 'Schizophrénie', 'Trouble bipolaire',
    'Anémie chronique', 'Drépanocytose', 'Thalassémie',
    'Psoriasis', 'Eczéma chronique', 'Vitiligo',
    'Glaucome', 'DMLA', 'Cataracte',
    'Reflux gastro-œsophagien', 'Maladie de Crohn', 'Rectocolite',
    'Migraine chronique', 'Fibromyalgie', 'Ostéoporose',
  ];

  static const List<String> typesExamenPredefines = [
    // Biologie
    'Numération formule sanguine (NFS)',
    'Glycémie à jeun', 'HbA1c', 'Bilan lipidique',
    'Créatinémie', 'Urée', 'Ionogramme sanguin',
    'Bilan hépatique (ASAT/ALAT)', 'Albumine', 'Protéines totales',
    'TSH', 'T4 libre', 'T3 libre',
    'CRP', 'VS', 'Fibrinogène',
    'Groupe sanguin', 'Sérologie VIH', 'Sérologie hépatite B/C',
    'ECBU (examen cytobactériologique des urines)',
    'Coproculture', 'Hémoculture',
    'PSA (antigène prostatique spécifique)',
    'Bêta-HCG (test de grossesse)',
    'Ferritine', 'Fer sérique', 'Acide folique', 'Vitamine B12',
    'Vitamine D', 'Calcium', 'Phosphore', 'Magnésium',
    // Imagerie
    'Radiographie thoracique', 'Radiographie des membres',
    'Radiographie du rachis', 'Radiographie abdominale',
    'Échographie abdominale', 'Échographie pelvienne',
    'Échographie cardiaque (échocardiographie)',
    'Échographie thyroïdienne', 'Échographie des membres',
    'Scanner (TDM) thoracique', 'Scanner abdominal', 'Scanner cérébral',
    'IRM cérébrale', 'IRM rachis', 'IRM articulaire',
    'Scintigraphie osseuse', 'Densitométrie osseuse (ostéodensitométrie)',
    'Mammographie',
    // Fonctionnel
    'Électrocardiogramme (ECG)', 'Holter ECG',
    'Épreuve d\'effort', 'Spirométrie (EFR)',
    'Électroencéphalogramme (EEG)',
    'Électromyogramme (EMG)',
    'Endoscopie digestive haute', 'Coloscopie',
    'Fibroscopie bronchique',
    'Fond d\'œil', 'Champ visuel',
  ];
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