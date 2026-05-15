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

  static const List<Map<String, String>> medicamentsPredefinis = [
  // ── Analgésiques / Anti-inflammatoires ────────────────
  {'nom': 'Paracétamol',        'molecule': 'Paracétamol',         'dosage': '500mg'},
  {'nom': 'Paracétamol',        'molecule': 'Paracétamol',         'dosage': '1000mg'},
  {'nom': 'Ibuprofène',         'molecule': 'Ibuprofène',          'dosage': '400mg'},
  {'nom': 'Ibuprofène',         'molecule': 'Ibuprofène',          'dosage': '600mg'},
  {'nom': 'Aspirine',           'molecule': 'Acide acétylsalicylique', 'dosage': '500mg'},
  {'nom': 'Aspirine cardio',    'molecule': 'Acide acétylsalicylique', 'dosage': '100mg'},
  {'nom': 'Diclofénac',         'molecule': 'Diclofénac sodique',  'dosage': '50mg'},
  {'nom': 'Kétoprofène',        'molecule': 'Kétoprofène',         'dosage': '100mg'},
  {'nom': 'Naproxène',          'molecule': 'Naproxène sodique',   'dosage': '550mg'},
  {'nom': 'Tramadol',           'molecule': 'Tramadol chlorhydrate','dosage': '50mg'},
  {'nom': 'Codéine',            'molecule': 'Phosphate de codéine','dosage': '30mg'},
  {'nom': 'Morphine',           'molecule': 'Sulfate de morphine', 'dosage': '10mg'},

  // ── Antibiotiques ─────────────────────────────────────
  {'nom': 'Amoxicilline',       'molecule': 'Amoxicilline',        'dosage': '500mg'},
  {'nom': 'Amoxicilline',       'molecule': 'Amoxicilline',        'dosage': '1000mg'},
  {'nom': 'Augmentin',          'molecule': 'Amoxicilline + Acide clavulanique', 'dosage': '875mg/125mg'},
  {'nom': 'Azithromycine',      'molecule': 'Azithromycine',       'dosage': '500mg'},
  {'nom': 'Clarithromycine',    'molecule': 'Clarithromycine',     'dosage': '500mg'},
  {'nom': 'Ciprofloxacine',     'molecule': 'Ciprofloxacine',      'dosage': '500mg'},
  {'nom': 'Doxycycline',        'molecule': 'Doxycycline',         'dosage': '100mg'},
  {'nom': 'Métronidazole',      'molecule': 'Métronidazole',       'dosage': '500mg'},
  {'nom': 'Céfixime',           'molecule': 'Céfixime',            'dosage': '400mg'},
  {'nom': 'Cotrimoxazole',      'molecule': 'Triméthoprime + Sulfaméthoxazole', 'dosage': '960mg'},

  // ── Cardiovasculaires ──────────────────────────────────
  {'nom': 'Amlodipine',         'molecule': 'Amlodipine',          'dosage': '5mg'},
  {'nom': 'Amlodipine',         'molecule': 'Amlodipine',          'dosage': '10mg'},
  {'nom': 'Ramipril',           'molecule': 'Ramipril',            'dosage': '5mg'},
  {'nom': 'Lisinopril',         'molecule': 'Lisinopril',          'dosage': '10mg'},
  {'nom': 'Losartan',           'molecule': 'Losartan potassique', 'dosage': '50mg'},
  {'nom': 'Valsartan',          'molecule': 'Valsartan',           'dosage': '160mg'},
  {'nom': 'Bisoprolol',         'molecule': 'Bisoprolol fumarate', 'dosage': '5mg'},
  {'nom': 'Aténolol',           'molecule': 'Aténolol',            'dosage': '50mg'},
  {'nom': 'Métoprolol',         'molecule': 'Métoprolol tartrate', 'dosage': '50mg'},
  {'nom': 'Furosémide',         'molecule': 'Furosémide',          'dosage': '40mg'},
  {'nom': 'Hydrochlorothiazide','molecule': 'Hydrochlorothiazide', 'dosage': '25mg'},
  {'nom': 'Spironolactone',     'molecule': 'Spironolactone',      'dosage': '25mg'},
  {'nom': 'Atorvastatine',      'molecule': 'Atorvastatine calcique','dosage': '20mg'},
  {'nom': 'Rosuvastatine',      'molecule': 'Rosuvastatine',       'dosage': '10mg'},
  {'nom': 'Simvastatine',       'molecule': 'Simvastatine',        'dosage': '20mg'},
  {'nom': 'Clopidogrel',        'molecule': 'Clopidogrel',         'dosage': '75mg'},
  {'nom': 'Digoxine',           'molecule': 'Digoxine',            'dosage': '0,25mg'},
  {'nom': 'Nitroglycérine',     'molecule': 'Trinitrate de glycéryle','dosage': '0,5mg'},

  // ── Diabète ───────────────────────────────────────────
  {'nom': 'Metformine',         'molecule': 'Metformine chlorhydrate','dosage': '500mg'},
  {'nom': 'Metformine',         'molecule': 'Metformine chlorhydrate','dosage': '1000mg'},
  {'nom': 'Glibenclamide',      'molecule': 'Glibenclamide',       'dosage': '5mg'},
  {'nom': 'Gliclazide',         'molecule': 'Gliclazide',          'dosage': '80mg'},
  {'nom': 'Sitagliptine',       'molecule': 'Sitagliptine',        'dosage': '100mg'},
  {'nom': 'Insuline rapide',    'molecule': 'Insuline humaine',    'dosage': '100 UI/mL'},
  {'nom': 'Insuline lente',     'molecule': 'Insuline glargine',   'dosage': '100 UI/mL'},

  // ── Respiratoire ──────────────────────────────────────
  {'nom': 'Salbutamol',         'molecule': 'Salbutamol',          'dosage': '100µg/dose'},
  {'nom': 'Béclométasone',      'molecule': 'Béclométasone dipropionate','dosage': '250µg/dose'},
  {'nom': 'Fluticasone',        'molecule': 'Propionate de fluticasone','dosage': '125µg/dose'},
  {'nom': 'Montélukast',        'molecule': 'Montélukast sodique', 'dosage': '10mg'},
  {'nom': 'Tiotropium',         'molecule': 'Tiotropium',          'dosage': '18µg'},
  {'nom': 'Prednisolone',       'molecule': 'Prednisolone',        'dosage': '5mg'},
  {'nom': 'Prednisolone',       'molecule': 'Prednisolone',        'dosage': '20mg'},

  // ── Gastro-entérologie ────────────────────────────────
  {'nom': 'Oméprazole',         'molecule': 'Oméprazole',          'dosage': '20mg'},
  {'nom': 'Oméprazole',         'molecule': 'Oméprazole',          'dosage': '40mg'},
  {'nom': 'Pantoprazole',       'molecule': 'Pantoprazole',        'dosage': '40mg'},
  {'nom': 'Ranitidine',         'molecule': 'Ranitidine',          'dosage': '150mg'},
  {'nom': 'Dompéridone',        'molecule': 'Dompéridone',         'dosage': '10mg'},
  {'nom': 'Métoclopramide',     'molecule': 'Métoclopramide',      'dosage': '10mg'},
  {'nom': 'Lopéramide',         'molecule': 'Lopéramide',          'dosage': '2mg'},
  {'nom': 'Hyoscine',           'molecule': 'Butylscopolamine',    'dosage': '10mg'},
  {'nom': 'Lactulose',          'molecule': 'Lactulose',           'dosage': '10g/15mL'},

  // ── Thyroïde ──────────────────────────────────────────
  {'nom': 'Lévothyroxine',      'molecule': 'Lévothyroxine sodique','dosage': '50µg'},
  {'nom': 'Lévothyroxine',      'molecule': 'Lévothyroxine sodique','dosage': '100µg'},
  {'nom': 'Carbimazole',        'molecule': 'Carbimazole',         'dosage': '5mg'},

  // ── Neurologie / Psychiatrie ──────────────────────────
  {'nom': 'Sertraline',         'molecule': 'Sertraline',          'dosage': '50mg'},
  {'nom': 'Fluoxétine',         'molecule': 'Fluoxétine',          'dosage': '20mg'},
  {'nom': 'Amitriptyline',      'molecule': 'Amitriptyline',       'dosage': '25mg'},
  {'nom': 'Alprazolam',         'molecule': 'Alprazolam',          'dosage': '0,25mg'},
  {'nom': 'Diazépam',           'molecule': 'Diazépam',            'dosage': '5mg'},
  {'nom': 'Zolpidem',           'molecule': 'Zolpidem tartrate',   'dosage': '10mg'},
  {'nom': 'Carbamazépine',      'molecule': 'Carbamazépine',       'dosage': '200mg'},
  {'nom': 'Valproate',          'molecule': 'Acide valproïque',    'dosage': '500mg'},
  {'nom': 'Lévétiracétam',      'molecule': 'Lévétiracétam',      'dosage': '500mg'},
  {'nom': 'Halopéridol',        'molecule': 'Halopéridol',         'dosage': '5mg'},

  // ── Vitamines / Compléments ───────────────────────────
  {'nom': 'Vitamine D3',        'molecule': 'Cholécalciférol',     'dosage': '1000 UI'},
  {'nom': 'Vitamine B12',       'molecule': 'Cyanocobalamine',     'dosage': '1000µg'},
  {'nom': 'Acide folique',      'molecule': 'Acide folique',       'dosage': '5mg'},
  {'nom': 'Fer',                'molecule': 'Sulfate ferreux',     'dosage': '80mg'},
  {'nom': 'Calcium',            'molecule': 'Carbonate de calcium','dosage': '500mg'},
  {'nom': 'Magnésium',          'molecule': 'Oxyde de magnésium',  'dosage': '300mg'},
  {'nom': 'Zinc',               'molecule': 'Gluconate de zinc',   'dosage': '15mg'},

  // ── Antihistaminiques ─────────────────────────────────
  {'nom': 'Cétirizine',         'molecule': 'Cétirizine',          'dosage': '10mg'},
  {'nom': 'Loratadine',         'molecule': 'Loratadine',          'dosage': '10mg'},
  {'nom': 'Desloratadine',      'molecule': 'Desloratadine',       'dosage': '5mg'},
  {'nom': 'Hydroxyzine',        'molecule': 'Hydroxyzine',         'dosage': '25mg'},

  // ── Dermatologie ──────────────────────────────────────
  {'nom': 'Bétaméthasone',      'molecule': 'Dipropionate de bétaméthasone','dosage': '0,05%'},
  {'nom': 'Hydrocortisone',     'molecule': 'Hydrocortisone',      'dosage': '1%'},
  {'nom': 'Kétoconazole',       'molecule': 'Kétoconazole',        'dosage': '200mg'},
  {'nom': 'Fluconazole',        'molecule': 'Fluconazole',         'dosage': '150mg'},
  {'nom': 'Terbinafine',        'molecule': 'Terbinafine',         'dosage': '250mg'},

  // ── Rhumatologie / Ostéoporose ────────────────────────
  {'nom': 'Alendronate',        'molecule': 'Alendronate sodique', 'dosage': '70mg'},
  {'nom': 'Colchicine',         'molecule': 'Colchicine',          'dosage': '1mg'},
  {'nom': 'Allopurinol',        'molecule': 'Allopurinol',         'dosage': '300mg'},
  {'nom': 'Hydroxychloroquine', 'molecule': 'Hydroxychloroquine',  'dosage': '200mg'},
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