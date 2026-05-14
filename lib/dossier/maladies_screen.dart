import 'package:carnetdesante/services/notification_service.dart';
import 'package:carnetdesante/services/referentiel_service.dart';
import 'package:carnetdesante/widgets/suggestion_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MaladiesScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> dossier;

  const MaladiesScreen(
      {super.key, required this.uid, required this.dossier});

  @override
  State<MaladiesScreen> createState() =>
      _MaladiesScreenState();
}

class _MaladiesScreenState extends State<MaladiesScreen> {
  static const Color primary = Color(0xFF1BC2AB);
  late List<Map<String, dynamic>> _maladies;

  @override
  void initState() {
    super.initState();
    _maladies = List<Map<String, dynamic>>.from(
      (widget.dossier['maladies'] as List? ?? [])
          .map((m) => Map<String, dynamic>.from(m)),
    );
  }

  Future<void> _sauvegarder() async {
    await FirebaseFirestore.instance
        .collection('Dossier_Medical')
        .doc(widget.uid)
        .update({'maladies': _maladies});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color(0xFF1B2B27)),
        title: const Text('Maladies chroniques',
            style: TextStyle(
                color: Color(0xFF1B2B27),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _ajouterMaladie(),
              icon: const Icon(Icons.add,
                  size: 16, color: Colors.white),
              label: const Text('Ajouter',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: _maladies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.healing_outlined,
                      size: 70, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  const Text('Aucune maladie chronique',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B2B27))),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _maladies.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final maladie = _maladies[i];
                final List meds = maladie['medicaments']
                        as List? ??
                    [];
                return InkWell(
                  onTap: () => _voirMaladie(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                          color: primary.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.healing_outlined,
                              color: primary,
                              size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                maladie['nomMaladie'] ?? '',
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 15,
                                    color:
                                        Color(0xFF1B2B27)),
                              ),
                              Text(
                                '${meds.length} médicament${meds.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20),
                          onPressed: () =>
                              _supprimerMaladie(i),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

void _ajouterMaladie() {
  final ctrl = TextEditingController();
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20))),
    // ✅ sheetCtx = contexte du bottom sheet
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nouvelle maladie chronique',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 16),
            SuggestionField(
              label: 'Nom de la maladie',
              icon: Icons.healing_outlined,
              color: primary,
              collection: 'MaladiesRef',
              displayField: 'nomMaladie',
              controller: ctrl,
              selectedData: {},
              onSelected: (data) {
                ctrl.text = data['nomMaladie'] ?? '';
              },
              onAutre: null,
              showAutre: false,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12))),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (ctrl.text.trim().isEmpty) return;
                        setLocal(() => isSaving = true);
                        setState(() {
                          _maladies.add({
                            'nomMaladie': ctrl.text.trim(),
                            'medicaments': [],
                          });
                        });
                        await _sauvegarder();
                        await ReferentielService
                            .sauvegarderMaladie(
                                ctrl.text.trim());
                        // ✅ sheetCtx défini dans builder
                        if (sheetCtx.mounted) {
                          Navigator.pop(sheetCtx);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Text('Ajouter',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _supprimerMaladie(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer'),
        content: Text(
            'Supprimer "${_maladies[index]['nomMaladie']}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _maladies.removeAt(index));
    await _sauvegarder();
  }

  void _voirMaladie(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailMaladie(
          maladie: _maladies[index],
          uid: widget.uid,
          onSave: (updated) async {
            setState(() => _maladies[index] = updated);
            await _sauvegarder();
          },
        ),
      ),
    );
  }
}

// ── Détail maladie + médicaments ─────────────────────────────────────────────
class _DetailMaladie extends StatefulWidget {
  final Map<String, dynamic> maladie;
  final String uid;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _DetailMaladie(
      {required this.maladie,
      required this.uid,
      required this.onSave});

  @override
  State<_DetailMaladie> createState() =>
      _DetailMaladieState();
}

class _DetailMaladieState extends State<_DetailMaladie> {
  static const Color primary = Color(0xFF1BC2AB);
  late List<Map<String, dynamic>> _medicaments;

  @override
  void initState() {
    super.initState();
    _medicaments = List<Map<String, dynamic>>.from(
      (widget.maladie['medicaments'] as List? ?? [])
          .map((m) => Map<String, dynamic>.from(m)),
    );
  }

  Future<void> _save() async {
    final updated = {
      ...widget.maladie,
      'medicaments': _medicaments,
    };
    await widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color(0xFF1B2B27)),
        title: Text(
          widget.maladie['nomMaladie'] ?? '',
          style: const TextStyle(
              color: Color(0xFF1B2B27),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _ajouterMedicament(),
              icon: const Icon(Icons.add,
                  size: 16, color: Colors.white),
              label: const Text('Médicament',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: _medicaments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 60, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  const Text('Aucun médicament',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B2B27))),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _medicaments.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1),
              itemBuilder: (context, i) {
                final med = _medicaments[i];
                final bool rappelActif =
                    med['rappelActif'] == true ||
                    med['rappelActif'].toString() == 'true';

                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withOpacity(
                            rappelActif ? 0.4 : 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Nom
                          Expanded(
                            child: Text(
                              med['nom'] ?? '',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 15,
                                  color:
                                      Color(0xFF1B2B27)),
                            ),
                          ),
                          // Toggle rappel
                          Row(children: [
                            Icon(
                              rappelActif
                                  ? Icons
                                      .notifications_active
                                  : Icons.notifications_none,
                              size: 18,
                              color: rappelActif
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            Switch(
                              value: rappelActif,
                              activeColor: Colors.orange,
                              onChanged: (v) =>
                                  _toggleRappel(i, v),
                            ),
                          ]),
                          // Supprimer
                          GestureDetector(
                            onTap: () =>
                                _supprimerMed(i),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.red
                                    .withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 14),
                            ),
                          ),
                        ],
                      ),

                      // Détails
                      if ((med['dosage']?.toString() ?? '').isNotEmpty)
                        _MedDetail(
                            label: 'Dosage',
                            value: med['dosage'].toString()),

                      if ((med['frequence']?.toString() ?? '').isNotEmpty)
                        _MedDetail(
                            label: 'Fréquence',
                            value: med['frequence'].toString()),

                      // Heures si rappel actif
                      if (rappelActif) ...[
                        const SizedBox(height: 8),
                        const Text('Heures de prise',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight:
                                    FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: ((med['heures']
                                      as List?) ??
                                  [])
                              .map<Widget>((h) => GestureDetector(
                                    onTap: () =>
                                        _modifierHeure(
                                            i,
                                            (med['heures']
                                                    as List)
                                                .indexOf(h)),
                                    child: Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 10,
                                              vertical: 5),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.orange
                                            .withOpacity(
                                                0.1),
                                        borderRadius:
                                            BorderRadius
                                                .circular(8),
                                        border: Border.all(
                                            color: Colors
                                                .orange
                                                .withOpacity(
                                                    0.3)),
                                      ),
                                      child: Text(
                                          h.toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              color: Colors
                                                  .orange)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _ajouterMedicament() {
    final nomCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl =
        TextEditingController(text: '1/1');
    bool rappel = false;
    List<String> heures = [''];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Ajouter un médicament',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 16),
                _MField(ctrl: nomCtrl, label: 'Nom du médicament', icon: Icons.medication_outlined),
                _MField(ctrl: dosageCtrl, label: 'Dosage', icon: Icons.science_outlined),
                _MField(ctrl: freqCtrl, label: 'Fréquence (ex: 2/1)', icon: Icons.repeat,
                    onChanged: (v) {
                  int n = _parseFreq(v);
                  setLocal(() {
                    while (heures.length < n) heures.add('');
                    while (heures.length > n) heures.removeLast();
                  });
                }),

                // Toggle rappel
                Row(children: [
                  const Text('Activer le rappel',
                      style: TextStyle(
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Switch(
                    value: rappel,
                    activeColor: Colors.orange,
                    onChanged: (v) => setLocal(() {
                      rappel = v;
                      if (v) {
                        int n = _parseFreq(freqCtrl.text);
                        heures = List.filled(n, '');
                      }
                    }),
                  ),
                ]),

                // Heures
                if (rappel) ...[
                  const Text('Heures de prise',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: List.generate(
                      heures.length,
                      (i) => GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (ctx2, child) =>
                                Theme(
                              data: Theme.of(ctx2)
                                  .copyWith(
                                colorScheme:
                                    const ColorScheme
                                        .light(
                                        primary: Colors
                                            .orange),
                              ),
                              child: child!,
                            ),
                          );
                          if (t != null) {
                            setLocal(() {
                              heures[i] =
                                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets
                              .symmetric(
                              horizontal: 14,
                              vertical: 8),
                          decoration: BoxDecoration(
                            color: heures[i].isEmpty
                                ? Colors.grey[100]
                                : Colors.orange
                                    .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                              color: heures[i].isEmpty
                                  ? Colors.grey[300]!
                                  : Colors.orange,
                            ),
                          ),
                          child: Text(
                            heures[i].isEmpty
                                ? 'Prise ${i + 1}'
                                : heures[i],
                            style: TextStyle(
                              color: heures[i].isEmpty
                                  ? Colors.grey
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12))),
                    onPressed: () async {
                      if (nomCtrl.text.trim().isEmpty)
                        return;
                      final newMed = {
                        'nom': nomCtrl.text.trim(),
                        'dosage': dosageCtrl.text.trim(),
                        'frequence': freqCtrl.text.trim(),
                        'rappelActif': rappel,
                        'heures': heures,
                      };
                      setState(() =>
                          _medicaments.add(newMed));
                      await _save();

                      // ✅ Si rappel actif → ajoute dans Rappels/Medicaments
                      if (rappel &&
                          heures
                              .every((h) => h.isNotEmpty)) {
                        await _planifierRappel(newMed);
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Ajouter',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _planifierRappel(
      Map<String, dynamic> med) async {
    final List<int> notifIds = [];
    for (var h in (med['heures'] as List? ?? [])) {
      final parts = h.toString().split(':');
      if (parts.length != 2) continue;
      final tod = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]));
      final id = NotificationService().genererID();
      await NotificationService().planifierRappelQuotidien(
        id: id,
        titre: '💊 ${med['nom']}',
        corps: (med['dosage'] ?? '').isNotEmpty
            ? 'Dose : ${med['dosage']}'
            : 'Heure de prendre votre médicament',
        heure: tod,
      );
      notifIds.add(id);
    }
    await FirebaseFirestore.instance
        .collection('Rappels')
        .doc(widget.uid)
        .collection('Medicaments')
        .add({
      'nom': med['nom'],
      'dosage': med['dosage'] ?? '',
      'frequence': med['frequence'] ?? '1/1',
      'heures': med['heures'],
      'estAlarme': false,
      'actif': true,
      'source': 'chronique',
      'sourceMaladie':
          widget.maladie['nomMaladie'] ?? '',
      'notificationIds': notifIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleRappel(int i, bool v) async {
    setState(() => _medicaments[i]['rappelActif'] = v);

    if (v) {
      // Activer → planifier rappel
      final med = _medicaments[i];
      if ((med['heures'] as List? ?? [])
          .every((h) => h.toString().isNotEmpty)) {
        await _planifierRappel(med);
      }
    } else {
      // Désactiver → supprimer de Rappels
      final nom = _medicaments[i]['nom'] ?? '';
      final snap = await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(widget.uid)
          .collection('Medicaments')
          .where('nom', isEqualTo: nom)
          .where('source', isEqualTo: 'chronique')
          .get();
      for (var doc in snap.docs) {
        final ids =
            doc.data()['notificationIds'] as List? ?? [];
        for (var id in ids) {
          await NotificationService()
              .annulerRappel(id as int);
        }
        await doc.reference.delete();
      }
    }
    await _save();
  }

  Future<void> _supprimerMed(int i) async {
    // Supprime aussi le rappel
    if (_medicaments[i]['rappelActif'] == true) {
      await _toggleRappel(i, false);
    }
    setState(() => _medicaments.removeAt(i));
    await _save();
  }

  Future<void> _modifierHeure(
      int medIndex, int heureIndex) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;
    setState(() {
      (_medicaments[medIndex]['heures'] as List)[heureIndex] =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    });
    await _save();
  }

  int _parseFreq(String f) {
    if (f.contains('/'))
      return int.tryParse(f.split('/')[0].trim()) ?? 1;
    return int.tryParse(f.trim()) ?? 1;
  }
}

class _MedDetail extends StatelessWidget {
  final String label;
  final String value;
  const _MedDetail(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Text('$label : ',
            style: TextStyle(
                fontSize: 12, color: Colors.grey[500])),
        Text(value,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF1B2B27))),
      ]),
    );
  }
}

class _MField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isNum;
  final ValueChanged<String>? onChanged;

  const _MField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.isNum = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType:
            isNum ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, color: const Color(0xFF1BC2AB)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF1BC2AB), width: 1.5),
          ),
        ),
      ),
    );
  }
}