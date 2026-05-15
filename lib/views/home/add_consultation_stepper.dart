// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:carnetdesante/services/notification_service.dart';
import 'package:carnetdesante/services/referentiel_service.dart';
import 'package:carnetdesante/widgets/suggestion_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';

class MedecinEntry {
  String nom = '';
  String prenom = '';
  String specialite = '';
  String telephone = '';
  String adresseCabinet = '';
}

class AddConsultationStepper extends StatefulWidget {
  final Map<String, dynamic>? consultationData;
  final String? docId;


  const AddConsultationStepper({super.key, this.consultationData, this.docId});

  @override
  State<AddConsultationStepper> createState() => _AddConsultationStepperState();
}

class _AddConsultationStepperState extends State<AddConsultationStepper> {
  final List<Map<String, TextEditingController>> _medControllers = [];
  final List<TextEditingController> _examenTypeControllers = [];
  // ── Médecin ──────────────────────────────────────────────
  final TextEditingController _medecinNomCtrl       = TextEditingController();
  final TextEditingController _medecinPrenomCtrl    = TextEditingController();
  final TextEditingController _medecinSpecialiteCtrl= TextEditingController();
  final TextEditingController _medecinTelCtrl       = TextEditingController();
  final TextEditingController _medecinAdresseCtrl   = TextEditingController();
  Map<String, dynamic> _medecinSelectionne = {};
@override
void initState() {
  super.initState();
  if (widget.consultationData != null) {
    final d = widget.consultationData!;
    _dateController.text       = d['date']         ?? '';
    _motifController.text      = d['motif']        ?? '';
    _diagnosticController.text = d['diagnostic']   ?? '';
    _obsController.text        = d['observations'] ?? '';
    _poidsController.text      = d['poids']        ?? '';
    _tailleController.text     = d['taille']       ?? '';
    _tensionController.text    = d['tension']      ?? '';
    _glycemieController.text   = d['glycemie']     ?? '';
    _medecinNomCtrl.text        = d['medecinNom']        ?? '';
    _medecinPrenomCtrl.text     = d['medecinPrenom']     ?? '';
    _medecinSpecialiteCtrl.text = d['medecinSpecialite'] ?? '';
    _medecinTelCtrl.text        = d['medecinTel']        ?? '';
    _medecinAdresseCtrl.text    = d['medecinAdresse']    ?? '';

    // ✅ Charge les médicaments existants avec leurs controllers
    final existingMeds = d['medicaments'] as List? ?? [];
    for (var med in existingMeds) {
      medicaments.add({
        'nom':       med['nom']       ?? '',
        'molecule':  med['molecule']  ?? '',
        'dosage':    med['dosage']    ?? '',
        'frequence': med['frequence'] ?? '',
        'duree':     med['duree']     ?? '',
      });
      _medControllers.add({
        'nom':       TextEditingController(text: med['nom']       ?? ''),
        'molecule':  TextEditingController(text: med['molecule']  ?? ''),
        'dosage':    TextEditingController(text: med['dosage']    ?? ''),
        'frequence': TextEditingController(text: med['frequence'] ?? ''),
        'duree':     TextEditingController(text: med['duree']     ?? ''),
      });
    }

    // ✅ Charge les examens existants avec leurs controllers
    final existingExamens = d['examens'] as List? ?? [];
    for (var ex in existingExamens) {
      examens.add({
        'type': ex['type'] ?? '',
        'date': ex['date'] ?? '',
        // ✅ Conserve la photo existante
        'photoExamenBase64': ex['photoExamenBase64'] ?? '',
      });
      _examenTypeControllers.add(
        TextEditingController(text: ex['type'] ?? ''),
      );
    }
  }
}
@override
void dispose() {
    _dateController.dispose();
    _motifController.dispose();
    _diagnosticController.dispose();
    _obsController.dispose();
    _poidsController.dispose();
    _tailleController.dispose();
    _tensionController.dispose();
    _glycemieController.dispose();
    _medecinNomCtrl.dispose();
    _medecinPrenomCtrl.dispose();
    _medecinSpecialiteCtrl.dispose();
    _medecinTelCtrl.dispose();
    _medecinAdresseCtrl.dispose();
    for (var ctrlMap in _medControllers) {
        for (var ctrl in ctrlMap.values) ctrl.dispose();
      }

    for (var ctrl in _examenTypeControllers) {
      ctrl.dispose();
    }
  super.dispose();
}
  int _currentStep = 1; 
  bool _isLoading = false;// On commence à l'étape 1
  final Color primaryColor = const Color(0xFF1BC2AB);
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLEURS ET DONNÉES ---
  final TextEditingController _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _diagnosticController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

  // Étape 2: Mesures
  final TextEditingController _poidsController = TextEditingController();
  final TextEditingController _tailleController = TextEditingController();
  final TextEditingController _tensionController = TextEditingController();
  final TextEditingController _glycemieController = TextEditingController();

  // Étape 3: Ordonnance
  Map<String, dynamic> ordonnanceFile = {'file': null, 'fileName': null};
  List<Map<String, dynamic>> medicaments = [];

  // Étape 4: Examens
  List<Map<String, dynamic>> examens = [];
  

  // --- LOGIQUE MÉDIA ---
  Future<void> _pickMedia(Map<String, dynamic> target, bool isCamera) async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 25, // <--- TRÈS IMPORTANT : réduit la taille à ~200-500 Ko
      maxWidth: 800,
      );
    if (picked != null) {
      setState(() {
        target['file'] = File(picked.path);
        target['fileName'] = picked.name;
      });
    }
  }
  Future<void> _selectExamenDate(int index) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        examens[index]['date'] = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // --- WIDGETS DE CONSTRUCTION ---

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          int stepNum = index + 1;
          bool isActive = _currentStep == stepNum;
          bool isCompleted = _currentStep > stepNum;

          return Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isCompleted || isActive ? primaryColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text("$stepNum", style: TextStyle(color: isActive ? Colors.white : primaryColor, fontWeight: FontWeight.bold)),
                ),
              ),
              if (index < 3)
                Container(
                  width: 40,
                  height: 2,
                  color: isCompleted ? primaryColor : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }


  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool isNum = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            hintText: hint ?? label,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildMediaSelector(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(15),
        color: primaryColor.withOpacity(0.02),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _mediaOption(Icons.camera_alt, "Appareil photo", () => _pickMedia(data, true)),
              _mediaOption(Icons.photo_library, "Galerie", () => _pickMedia(data, false)),
              _mediaOption(Icons.picture_as_pdf, "Fichier", () {}),
            ],
          ),
          if (data['fileName'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  data['file'], 
                  height: 100, 
                  width: double.infinity, 
                  fit: BoxFit.cover
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 30),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Nouvelle Consultation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        actions: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),
            _buildFooterButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(_dateController, "Date de la consultation",
              Icons.calendar_today),
          _buildTextField(_motifController, "Motif de la visite",
              Icons.notes, maxLines: 2),
          _buildTextField(_diagnosticController, "Diagnostic",
              Icons.medical_services_outlined),
          _buildTextField(_obsController, "Observations",
              Icons.description, maxLines: 3),

          // ✅ Nouveau bloc médecin
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          const Text("Informations du Médecin (optionnel)",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1BC2AB))),
          const SizedBox(height: 12),
          SuggestionField(
            label: 'Nom du médecin',
            icon: Icons.person_outline,
            color: primaryColor,
            collection: 'Medecins',
            displayField: 'nomComplet',
            controller: _medecinNomCtrl,
            selectedData: _medecinSelectionne,
            onSelected: (data) {
              setState(() {
                _medecinSelectionne = data;
                _medecinPrenomCtrl.text = data['prenom'] ?? '';
                _medecinNomCtrl.text    = data['nom'] ?? '';
                _medecinSpecialiteCtrl.text   = data['specialite'] ?? '';
                _medecinTelCtrl.text    = data['tel'] ?? '';
                _medecinAdresseCtrl.text = data['adresse'] ?? '';
              });
            },
            onAutre: () {
              setState(() => _medecinSelectionne = {});
            },
          ),

          const SizedBox(height: 10),

          _buildTextField(
            _medecinPrenomCtrl,
            "Prénom",
            Icons.person_outline,
          ),
          _buildTextField(_medecinSpecialiteCtrl, "Spécialité",
              Icons.local_hospital_outlined),
          _buildTextField(_medecinTelCtrl, "Téléphone",
              Icons.phone_outlined),
          _buildTextField(_medecinAdresseCtrl, "Adresse du cabinet",
              Icons.location_on_outlined),
        ],
      );
      case 2:
        return Column(
          children: [
            const Text("Enregistrez vos mesures de santé (optionnel)", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _buildTextField(_poidsController, "Poids (kg)", Icons.monitor_weight, isNum: true),
            _buildTextField(_tailleController, "Taille (cm)", Icons.height, isNum: true),
            _buildTextField(_tensionController, "Tension artérielle", Icons.speed, hint: "Ex: 12/8 (Syst/Diast)"),
            _buildTextField(_glycemieController, "Glycémie (mmol/L)", Icons.opacity, isNum: true),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ordonnance ──────────────────────────────────
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long_outlined,
                    color: primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text("Ordonnance",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text("Optionnel",
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ]),
            const SizedBox(height: 10),
            _buildMediaSelector(ordonnanceFile),
            const SizedBox(height: 20),

            // ── Médicaments ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication_outlined,
                        color: Colors.blue, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text("Médicaments",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (medicaments.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${medicaments.length}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                TextButton.icon(
                  onPressed: () => setState(() {
                    medicaments.add({});
                    _medControllers.add({
                      'nom':       TextEditingController(),
                      'molecule':  TextEditingController(),
                      'dosage':    TextEditingController(),
                      'frequence': TextEditingController(),
                      'duree':     TextEditingController(),
                    });
                  }),
                  icon: const Icon(Icons.add, size: 16, color: Colors.blue),
                  label: const Text("Ajouter",
                      style: TextStyle(color: Colors.blue, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...medicaments.asMap().entries.map((e) => _buildMedEntry(e.key)),
          ],
        );
      case 4:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.biotech_outlined,
                      color: Colors.orange, size: 18),
                ),
                const SizedBox(width: 10),
                const Text("Examens",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (examens.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${examens.length}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              TextButton.icon(
                onPressed: () => setState(() {
                  examens.add({'type': '', 'date': ''});
                  _examenTypeControllers.add(TextEditingController());
                }),
                icon: const Icon(Icons.add, size: 16, color: Colors.orange),
                label: const Text("Ajouter",
                    style: TextStyle(color: Colors.orange, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...examens.asMap().entries.map((e) => _buildExamenEntry(e.key)),
        ],
      );
      default:
        return const SizedBox();
    }
  }

    Widget _buildMedEntry(int index) {
      final med         = medicaments[index];
      final controllers = _medControllers[index];

      // Couleur unique par médicament
      const Color color = Color(0xFF1BC2AB);

      return StatefulBuilder(
        builder: (context, localSetState) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── En-tête coloré ──────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(Icons.medication, color: color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text("Médicament ${index + 1}",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: color, fontSize: 13)),
                      const Spacer(),
                      // Icône rappel
                      GestureDetector(
                        onTap: () {
                          localSetState(() {
                            med['rappelActif'] = !(med['rappelActif'] == true);
                            if (med['rappelActif'] == true) {
                              int n = _parseFrequence(
                                  controllers['frequence']!.text.isEmpty
                                      ? '1/1'
                                      : controllers['frequence']!.text);
                              med['heures'] = List.filled(n, '');
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (med['rappelActif'] == true)
                                ? primaryColor.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (med['rappelActif'] == true)
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                                size: 15,
                                color: (med['rappelActif'] == true)
                                    ? primaryColor
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (med['rappelActif'] == true) ? "Rappel ON" : "Rappel",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: (med['rappelActif'] == true)
                                      ? primaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          for (var c in _medControllers[index].values) c.dispose();
                          _medControllers.removeAt(index);
                          medicaments.removeAt(index);
                        }),
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Champs ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      // Nom
                      SuggestionField(
                        label: 'Nom du médicament',
                        icon: Icons.medication_outlined,
                        color: color,
                        collection: 'Medicaments',
                        displayField: 'nom',
                        controller: controllers['nom']!,
                        selectedData: {},
                        onSelected: (data) {
                          setState(() {
                            controllers['nom']!.text      = data['nom']?.toString()      ?? '';
                            controllers['molecule']!.text = data['molecule']?.toString() ?? '';
                            controllers['dosage']!.text   = data['dosage']?.toString()   ?? '';
                            med['nom']      = controllers['nom']!.text;
                            med['molecule'] = controllers['molecule']!.text;
                            med['dosage']   = controllers['dosage']!.text;
                          });
                        },
                        showAutre: true,
                        onAutre: () {
                          // Vide les champs pour saisie manuelle
                          controllers['nom']!.clear();
                          controllers['molecule']!.clear();
                          controllers['dosage']!.clear();
                          med['nom']      = '';
                          med['molecule'] = '';
                          med['dosage']   = '';
                        },
                      ),
                      const SizedBox(height: 10),
                      // Molécule
                      _buildCleanField(
                        controller: controllers['molecule']!,
                        hint: "Molécule",
                        icon: Icons.science_outlined,
                        iconColor: color,
                        onChanged: (v) => med['molecule'] = v,
                      ),
                      const SizedBox(height: 10),
                      // Dosage + Fréquence
                      Row(children: [
                        Expanded(
                          child: _buildCleanField(
                            controller: controllers['dosage']!,
                            hint: "Dosage",
                            icon: Icons.colorize_outlined,
                            iconColor: color,
                            onChanged: (v) => med['dosage'] = v,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCleanField(
                            controller: controllers['frequence']!,
                            hint: "Fréq. (ex: 2/1)",
                            icon: Icons.repeat,
                            iconColor: color,
                            onChanged: (v) {
                              med['frequence'] = v;
                              if (med['rappelActif'] == true) {
                                int n = _parseFrequence(v.isEmpty ? '1/1' : v);
                                localSetState(() {
                                  med['heures'] = List.filled(n, '');
                                });
                              }
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      // Durée
                      _buildCleanField(
                        controller: controllers['duree']!,
                        hint: "Durée (jours)",
                        icon: Icons.timer_outlined,
                        iconColor: color,
                        isNum: true,
                        onChanged: (v) => med['duree'] = v,
                      ),

                      // Heures de prise
                      if (med['rappelActif'] == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.access_time,
                                    size: 14, color: primaryColor),
                                const SizedBox(width: 6),
                                Text("Heures de prise",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor)),
                              ]),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: List.generate(
                                  _parseFrequence(
                                      controllers['frequence']!.text.isEmpty
                                          ? '1/1'
                                          : controllers['frequence']!.text),
                                  (i) {
                                    final heures = med['heures'] as List? ?? [];
                                    while (heures.length <= i) heures.add('');
                                    med['heures'] = heures;
                                    final heure = heures[i].toString();

                                    return GestureDetector(
                                      onTap: () async {
                                        final t = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                          builder: (ctx, child) => Theme(
                                            data: Theme.of(ctx).copyWith(
                                              colorScheme: ColorScheme.light(
                                                  primary: primaryColor),
                                            ),
                                            child: child!,
                                          ),
                                        );
                                        if (t != null) {
                                          localSetState(() {
                                            (med['heures'] as List)[i] =
                                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: heure.isEmpty
                                              ? Colors.white
                                              : primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: heure.isEmpty
                                                ? Colors.grey[300]!
                                                : primaryColor,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time,
                                                size: 13,
                                                color: heure.isEmpty
                                                    ? Colors.grey
                                                    : primaryColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              heure.isEmpty
                                                  ? "Prise ${i + 1}"
                                                  : heure,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: heure.isEmpty
                                                    ? Colors.grey
                                                    : primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // ✅ Parse "2/1" → 2,  "1/1" → 1,  "3/1" → 3
    int _parseFrequence(String freq) {
      if (freq.contains('/')) {
        return int.tryParse(freq.split('/')[0].trim()) ?? 1;
      }
      return int.tryParse(freq.trim()) ?? 1;
    }

    Widget _buildExamenEntry(int index) {
    final ex = examens[index];

    const Color color = Color.fromARGB(255, 217, 145, 44);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.biotech_outlined, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text("Examen ${index + 1}",
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color, fontSize: 13)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    examens.removeAt(index);
                    _examenTypeControllers[index].dispose();
                    _examenTypeControllers.removeAt(index);
                  }),
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 14),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildMediaSelector(ex),
                const SizedBox(height: 12),
                // Type d'examen
                // ✅ Remplace le TextField type d'examen par :
                SuggestionField(
                  label: "Type d'examen",
                  icon: Icons.biotech_outlined,
                  color: color,
                  collection: 'TypesExamen',
                  displayField: 'type',
                  controller: _examenTypeControllers[index],
                  selectedData: {},
                  suggestionsLocales: ReferentielService.typesExamenPredefines,
                  onSelected: (data) {
                    setState(() {
                      examens[index]['type'] = data['type']?.toString() ?? '';
                      _examenTypeControllers[index].text = data['type']?.toString() ?? '';
                    });
                  },
                  showAutre: true,
                  onAutre: () {
                    _examenTypeControllers[index].clear();
                    examens[index]['type'] = '';
                  },
                ),
                const SizedBox(height: 10),
                // Date
                GestureDetector(
                  onTap: () => _selectExamenDate(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: (ex['date'] ?? '').isEmpty
                          ? Colors.grey[50]
                          : color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (ex['date'] ?? '').isEmpty
                            ? Colors.grey[300]!
                            : color.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            size: 18,
                            color: (ex['date'] ?? '').isEmpty
                                ? Colors.grey
                                : color),
                        const SizedBox(width: 10),
                        Text(
                          (ex['date'] ?? '').isEmpty
                              ? "Date de l'examen"
                              : ex['date'],
                          style: TextStyle(
                            fontSize: 14,
                            color: (ex['date'] ?? '').isEmpty
                                ? Colors.grey
                                : color,
                            fontWeight: (ex['date'] ?? '').isEmpty
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _currentStep > 1 ? () => setState(() => _currentStep--) : null,
            child: Text("Précédent", style: TextStyle(color: _currentStep > 1 ? Colors.grey : Colors.transparent)),
          ),
          ElevatedButton(
            onPressed: _isLoading 
              ? null // Désactive le bouton pendant l'envoi
              : () async {
                  if (_currentStep < 4) {
                    setState(() => _currentStep++);
                  } else {
                    // --- DÉBUT DE LA LOGIQUE DE SAUVEGARDE ---
                    setState(() => _isLoading = true);
                    try {
                      // 1. Préparation des données de base
                      Map<String, dynamic> consultData = {
                        'date': _dateController.text.trim(),
                        'motif': _motifController.text.trim(),
                        'diagnostic': _diagnosticController.text.trim(),
                        'observations': _obsController.text.trim(),
                        'poids': _poidsController.text.trim(),
                        'taille': _tailleController.text.trim(),
                        'tension': _tensionController.text.trim(),
                        'glycemie': _glycemieController.text.trim(),
                        'medecinNom':        _medecinNomCtrl.text.trim(),
                        'medecinPrenom':     _medecinPrenomCtrl.text.trim(),
                        'medecinSpecialite': _medecinSpecialiteCtrl.text.trim(),
                        'medecinTel':        _medecinTelCtrl.text.trim(),
                        'medecinAdresse':    _medecinAdresseCtrl.text.trim(),
                      };

                      // 2. Appel au service (on lui passe tout : fichiers, meds, examens)
                      await DatabaseService().saveFullConsultation(
                        consultData: consultData,
                        ordonnance: ordonnanceFile,
                        medicaments: medicaments,
                        examens: examens,
                        docId: widget.docId, // Utile pour la modification
                      );

                    // Médecin
                    if (_medecinNomCtrl.text.trim().isNotEmpty) {
                      await ReferentielService.sauvegarderMedecin(
                        nom:        _medecinNomCtrl.text.trim(),
                        prenom:     _medecinPrenomCtrl.text.trim(),
                        specialite: _medecinSpecialiteCtrl.text.trim(),
                        tel:        _medecinTelCtrl.text.trim(),
                        adresse:    _medecinAdresseCtrl.text.trim(),
                      );
                    }

                    // Médicaments
                    for (var med in medicaments) {
                      if ((med['nom'] ?? '').toString().isNotEmpty) {
                        await ReferentielService.sauvegarderMedicament(
                          nom:      med['nom'] ?? '',
                          molecule: med['molecule'] ?? '',
                          dosage:   med['dosage'] ?? '',
                        );
                      }
                    }

                    // Types d'examens
                    for (var ex in examens) {
                      if ((ex['type'] ?? '').toString().isNotEmpty) {
                        await ReferentielService.sauvegarderTypeExamen(
                            ex['type'] ?? '');
                      }
                    }
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    for (var med in medicaments) {
                      if (med['rappelActif'] == true) {
                        final List heures = med['heures'] as List? ?? [];
                        if (heures.every((h) => h.toString().isNotEmpty)) {
                          List<int> notifIds = [];
                          for (var heure in heures) {
                            final parts = heure.toString().split(':');
                            final tod = TimeOfDay(
                              hour:   int.parse(parts[0]),
                              minute: int.parse(parts[1]),
                            );
                            final id = NotificationService().genererID();
                            await NotificationService().planifierRappelQuotidien(
                              id:    id,
                              titre: "💊 ${med['nom'] ?? 'Médicament'}",
                              corps: (med['dosage'] ?? '').isNotEmpty
                                  ? "Dose : ${med['dosage']}"
                                  : "Heure de prendre votre médicament",
                              heure: tod,
                            );
                            notifIds.add(id);
                          }

                          // ✅ Sauvegarde directement dans Rappels/Medicaments
                          await FirebaseFirestore.instance
                              .collection('Rappels')
                              .doc(uid)
                              .collection('Medicaments')
                              .add({
                            'nom':             med['nom'] ?? '',
                            'dosage':          med['dosage'] ?? '',
                            'frequence':       med['frequence'] ?? '1/1',
                            'heures':          heures,
                            'actif':           true,
                            'source':          'consultation',
                            'sourceDate':      _dateController.text,
                            'notificationIds': notifIds,
                            'createdAt':       FieldValue.serverTimestamp(),
                          });
                        }
                      }
                    }

              // 3. Succès et retour arrière
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Consultation enregistrée !"),
                        backgroundColor: Color(0xFF1BC2AB),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  // En cas d'erreur (ex: pas d'internet)
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
            // --- FIN DE LA LOGIQUE DE SAUVEGARDE ---
          }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          ),
          child: _isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(_currentStep == 4 ? "Enregistrer" : "Suivant", 
          style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

    Widget buildImage(String url, String localPath) {
      if (url.startsWith("http")) {
        return Image.network(url);
      } else if (localPath.isNotEmpty) {
        return Image.file(File(localPath));
      } else {
        return const Text("📷 Image non disponible");
      }
    }
    Widget _buildCleanField({
      required TextEditingController controller,
      required String hint,
      required IconData icon,
      required Color iconColor,
      bool isNum = false,
      ValueChanged<String>? onChanged,
    }) {
      return TextField(
        controller: controller,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1B2B27)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: iconColor, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: iconColor, width: 1.5),
          ),
        ),
      );
    }
}