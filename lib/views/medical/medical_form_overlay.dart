// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:carnetdesante/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carnetdesante/services/notification_service.dart';
import 'package:flutter/material.dart';

// ── Modèles ───────────────────────────────────────────────────────────────────
class MedicationEntry {
  String nom = '';
  String dosage = '';
  int frequence = 1;
  List<String> heures = []; // ✅ stocke les heures
  bool rappelActif = false;
}

class DiseaseEntry {
  String nomMaladie = '';
  List<MedicationEntry> medicaments = [];
}

class AllergyEntry {
  String nomAllergie = '';
  String dateApparition = '';
}

// ── Widget principal ──────────────────────────────────────────────────────────
class MedicalFormOverlay extends StatefulWidget {
  const MedicalFormOverlay({super.key});

  @override
  State<MedicalFormOverlay> createState() => _MedicalFormOverlayState();
}

class _MedicalFormOverlayState extends State<MedicalFormOverlay> {
  static const Color primary = Color(0xFF1BC2AB);
  final _formKey = GlobalKey<FormState>();

  final _poidsCtrl    = TextEditingController();
  final _tailleCtrl   = TextEditingController();
  final _tensionCtrl  = TextEditingController();
  final _glycemieCtrl = TextEditingController();
  final _nssCtrl      = TextEditingController();
  final _hopitalCtrl  = TextEditingController();
  final _dateEntreeCtrl = TextEditingController();
  final _dateSortieCtrl = TextEditingController();

  String? _selectedBloodGroup;
  bool _hasHospitalisation = false;
  bool _isSaving = false;

  List<AllergyEntry> allergies = [];
  List<DiseaseEntry> maladies  = [];

  @override
  void dispose() {
    _poidsCtrl.dispose();
    _tailleCtrl.dispose();
    _tensionCtrl.dispose();
    _glycemieCtrl.dispose();
    _nssCtrl.dispose();
    _hopitalCtrl.dispose();
    _dateEntreeCtrl.dispose();
    _dateSortieCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    const Center(
                      child: Text(
                        "Compléter mon Dossier Médical",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        "Ces informations resteront confidentielles",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Informations vitales ──────────────────────────────
                    _SectionTitle(title: "Informations Vitales", icon: Icons.favorite_outline, required: true),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildField(_poidsCtrl, "Poids (kg)", Icons.monitor_weight, isNum: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField(_tailleCtrl, "Taille (cm)", Icons.height, isNum: true)),
                    ]),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodGroup,
                      decoration: _fieldStyle("Groupe sanguin *", Icons.bloodtype),
                      items: ["A+","A-","B+","B-","AB+","AB-","O+","O-"]
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBloodGroup = v),
                      validator: (v) => v == null ? "Champ obligatoire" : null,
                    ),

                    // ── Suivi optionnel ───────────────────────────────────
                    const SizedBox(height: 24),
                    _SectionTitle(title: "Suivi", icon: Icons.show_chart, required: false),
                    const SizedBox(height: 12),
                    _buildField(_tensionCtrl,  "Tension artérielle", Icons.speed),
                    _buildField(_glycemieCtrl, "Glycémie (mmol/L)",  Icons.opacity, isNum: true),
                    _buildField(_nssCtrl,      "N° Sécurité Sociale", Icons.badge),

                    // ── Allergies ─────────────────────────────────────────
                    const SizedBox(height: 24),
                    _DynamicHeader(
                      title: "Allergies",
                      icon: Icons.warning_amber_outlined,
                      count: allergies.length,
                      onAdd: () => setState(() => allergies.add(AllergyEntry())),
                    ),
                    const SizedBox(height: 8),
                    ...allergies.asMap().entries.map((e) => _buildAllergyTile(e.value, e.key)),

                    // ── Maladies chroniques ───────────────────────────────
                    const SizedBox(height: 24),
                    _DynamicHeader(
                      title: "Maladies Chroniques",
                      icon: Icons.healing_outlined,
                      count: maladies.length,
                      onAdd: () => setState(() => maladies.add(DiseaseEntry())),
                    ),
                    const SizedBox(height: 8),
                    ...maladies.asMap().entries.map((e) => _buildDiseaseTile(e.value, e.key)),

                    // ── Hospitalisation ───────────────────────────────────
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: _hasHospitalisation
                            ? primary.withOpacity(0.05)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasHospitalisation
                              ? primary.withOpacity(0.3)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: CheckboxListTile(
                        title: const Text("Avez-vous déjà été hospitalisé ?",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        value: _hasHospitalisation,
                        onChanged: (v) => setState(() => _hasHospitalisation = v!),
                        activeColor: primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (_hasHospitalisation) ...[
                      const SizedBox(height: 12),
                      _buildField(_hopitalCtrl, "Hôpital", Icons.local_hospital),
                      Row(children: [
                        Expanded(child: _buildField(_dateEntreeCtrl, "Date entrée", Icons.login)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField(_dateSortieCtrl, "Date sortie", Icons.logout)),
                      ]),
                    ],

                    // ── Bouton enregistrer ────────────────────────────────
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSaving ? null : _submitData,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text(
                                "Enregistrer le dossier",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Allergie tile ─────────────────────────────────────────────────────────
  Widget _buildAllergyTile(AllergyEntry allergy, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              const Text("Allergie",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => allergies.removeAt(index)),
                child: const Icon(Icons.close, color: Colors.red, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: _fieldStyle("Nom de l'allergie", Icons.label_outline),
            onChanged: (v) => allergy.nomAllergie = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: _fieldStyle("Date d'apparition (optionnel)",
                Icons.calendar_today_outlined),
            onChanged: (v) => allergy.dateApparition = v,
          ),
        ],
      ),
    );
  }

  // ── Maladie tile ──────────────────────────────────────────────────────────
  Widget _buildDiseaseTile(DiseaseEntry maladie, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1BC2AB).withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1BC2AB).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing_outlined,
                  color: Color(0xFF1BC2AB), size: 18),
              const SizedBox(width: 8),
              const Text("Maladie chronique",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => maladies.removeAt(index)),
                child: const Icon(Icons.close, color: Colors.red, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: _fieldStyle(
                "Nom de la maladie", Icons.medical_information_outlined),
            onChanged: (v) => setState(() => maladie.nomMaladie = v),
          ),
          if (maladie.nomMaladie.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Médicaments associés",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                TextButton.icon(
                  onPressed: () => setState(
                      () => maladie.medicaments.add(MedicationEntry())),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF1BC2AB)),
                  label: const Text("Ajouter",
                      style: TextStyle(
                          color: Color(0xFF1BC2AB), fontSize: 13)),
                ),
              ],
            ),
            ...maladie.medicaments.asMap().entries.map(
              (e) => _buildMedTile(e.value, maladie, e.key),
            ),
          ],
        ],
      ),
    );
  }

  // ── Médicament tile (dans maladie chronique) ──────────────────────────────
  Widget _buildMedTile(MedicationEntry med, DiseaseEntry maladie, int index) {
    return StatefulBuilder(
      builder: (context, localSet) {
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nom + supprimer ──
              Row(
                children: [
                  const Icon(Icons.medication_outlined,
                      size: 16, color: Color(0xFF1BC2AB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Nom du médicament",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) => med.nom = v,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(
                        () => maladie.medicaments.removeAt(index)),
                    child: const Icon(Icons.close,
                        color: Colors.red, size: 16),
                  ),
                ],
              ),
              const Divider(height: 12),

              // ── Dosage + Fréquence ──
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Dosage (ex: 500mg)",
                      border: InputBorder.none,
                      isDense: true,
                      prefixIcon: Icon(Icons.science_outlined,
                          size: 16, color: Colors.grey),
                    ),
                    onChanged: (v) => med.dosage = v,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Fréq/jour",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      localSet(() {
                        med.frequence = int.tryParse(v) ?? 1;
                        // ✅ Redimensionne la liste d'heures
                        while (med.heures.length < med.frequence) {
                          med.heures.add('');
                        }
                        while (med.heures.length > med.frequence) {
                          med.heures.removeLast();
                        }
                      });
                    },
                  ),
                ),
                // ── Icône rappel ──
                IconButton(
                  icon: Icon(
                    med.rappelActif
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: med.rappelActif
                        ? const Color(0xFF1BC2AB)
                        : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () {
                    localSet(() {
                      med.rappelActif = !med.rappelActif;
                      if (med.rappelActif) {
                        med.heures = List.filled(med.frequence, '');
                      }
                    });
                  },
                ),
              ]),

              // ✅ Champs heures si rappel actif
              if (med.rappelActif && med.frequence > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1BC2AB).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Heures de prise",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1BC2AB))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(med.frequence, (i) {
                          // ✅ S'assure que la liste est assez grande
                          while (med.heures.length <= i) med.heures.add('');

                          return GestureDetector(
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF1BC2AB)),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                // ✅ Stocke l'heure dans la liste
                                localSet(() {
                                  med.heures[i] =
                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: med.heures[i].isEmpty
                                    ? Colors.white
                                    : const Color(0xFF1BC2AB)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: med.heures[i].isEmpty
                                      ? Colors.grey[300]!
                                      : const Color(0xFF1BC2AB),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14,
                                      color: med.heures[i].isEmpty
                                          ? Colors.grey
                                          : const Color(0xFF1BC2AB)),
                                  const SizedBox(width: 4),
                                  Text(
                                    med.heures[i].isEmpty
                                        ? "Prise ${i + 1}"
                                        : med.heures[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: med.heures[i].isEmpty
                                          ? Colors.grey
                                          : const Color(0xFF1BC2AB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_poidsCtrl.text.isEmpty ||
        _tailleCtrl.text.isEmpty ||
        _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Veuillez remplir les champs obligatoires")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // ✅ 1. Convertit les maladies + médicaments en Map pour Firestore
      final List<Map<String, dynamic>> maladiesData = maladies.map((m) {
        return {
          'nomMaladie': m.nomMaladie,
          'medicaments': m.medicaments.map((med) => {
            'nom':         med.nom,
            'dosage':      med.dosage,
            'frequence':   med.frequence,
            'heures':      med.heures,
            'rappelActif': med.rappelActif,
          }).toList(),
        };
      }).toList();

      final List<Map<String, dynamic>> allergiesData = allergies.map((a) => {
        'nomAllergie':    a.nomAllergie,
        'dateApparition': a.dateApparition,
      }).toList();

      // ✅ 2. Sauvegarde dans Firestore
      await DatabaseService().saveInitialMedicalData(
        poids:         double.parse(_poidsCtrl.text),
        taille:        double.parse(_tailleCtrl.text),
        groupeSanguin: _selectedBloodGroup!,
        nss:           _nssCtrl.text,
      );

      // ✅ 3. Sauvegarde maladies, allergies, hospitalisation dans le même doc
      await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(uid)
          .update({
        'maladies':  maladiesData,
        'allergies': allergiesData,
        if (_hasHospitalisation) ...{
          'hospitalisation': {
            'hopital':    _hopitalCtrl.text,
            'dateEntree': _dateEntreeCtrl.text,
            'dateSortie': _dateSortieCtrl.text,
          }
        },
        'tension':  _tensionCtrl.text,
        'glycemie': _glycemieCtrl.text,
      });

      // ✅ 4. Planifie les rappels pour les médicaments chroniques avec rappelActif
      for (var maladie in maladies) {
        for (var med in maladie.medicaments) {
          if (med.rappelActif && med.heures.every((h) => h.isNotEmpty)) {
            List<int> notifIds = [];
            for (var heure in med.heures) {
              final parts = heure.split(':');
              final tod = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]));
              final id = NotificationService().genererID();
              await NotificationService().planifierRappelQuotidien(
                id:    id,
                titre: "💊 ${med.nom}",
                corps: med.dosage.isNotEmpty
                    ? "Dose : ${med.dosage}"
                    : "Heure de prendre votre médicament",
                heure: tod,
              );
              notifIds.add(id);
            }

            // ✅ 5. Sauvegarde le rappel dans Rappels/Medicaments
            await FirebaseFirestore.instance
                .collection('Rappels')
                .doc(uid)
                .collection('Medicaments')
                .add({
              'nom':             med.nom,
              'dosage':          med.dosage,
              'frequence':       med.frequence.toString(),
              'heures':          med.heures,
              'actif':           true,
              'source':          'chronique',
              'sourceMaladie':   maladie.nomMaladie,
              'notificationIds': notifIds,
              'createdAt':       FieldValue.serverTimestamp(),
            });
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Ferme le formulaire
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Dossier enregistré avec succès !"),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur : $e"),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: _fieldStyle(label, icon),
      ),
    );
  }

  InputDecoration _fieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1BC2AB), size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1BC2AB), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ── Widgets helper ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool required;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1BC2AB).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1BC2AB), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(" *",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}

class _DynamicHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final VoidCallback onAdd;

  const _DynamicHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1BC2AB), size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BC2AB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("$count",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline,
              color: Color(0xFF1BC2AB), size: 18),
          label: const Text("Ajouter",
              style: TextStyle(
                  color: Color(0xFF1BC2AB),
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}