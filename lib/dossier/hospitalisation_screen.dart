import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HospitalisationScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> dossier;

  const HospitalisationScreen(
      {super.key, required this.uid, required this.dossier});

  @override
  State<HospitalisationScreen> createState() =>
      _HospitalisationScreenState();
}

class _HospitalisationScreenState
    extends State<HospitalisationScreen> {
  static const Color bleu = Colors.blue;
  late List<Map<String, dynamic>> _hospitalisations;

  @override
  void initState() {
    super.initState();
    _hospitalisations = _parseHospitalisations(
        widget.dossier['hospitalisation']);
  }

  // ✅ Gère tous les formats possibles depuis Firestore
  List<Map<String, dynamic>> _parseHospitalisations(
      dynamic raw) {
    if (raw == null) return [];

    // Format liste (nouveau)
    if (raw is List) {
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    // Format Map avec clés entières (ex: {"0": {...}, "1": {...}})
    if (raw is Map) {
      // Vérifie si les clés sont des indices numériques
      final keys = raw.keys.toList();
      final isIndexed = keys.every((k) =>
          int.tryParse(k.toString()) != null);

      if (isIndexed) {
        // ✅ Map indexée → convertit en liste
        final sorted = keys
          ..sort((a, b) => int.parse(a.toString())
              .compareTo(int.parse(b.toString())));
        return sorted
            .map((k) =>
                Map<String, dynamic>.from(raw[k] as Map))
            .toList();
      }

      // Format objet unique (ex: {"hopital": "ehu", ...})
      final h = Map<String, dynamic>.from(raw);
      final hasData = h.values.any(
          (v) => v != null && v.toString().isNotEmpty);
      return hasData ? [h] : [];
    }

    return [];
  }

  Future<void> _sauvegarder() async {
    await FirebaseFirestore.instance
        .collection('Dossier_Medical')
        .doc(widget.uid)
        .update({'hospitalisation': _hospitalisations});
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
        title: const Text('Hospitalisations',
            style: TextStyle(
                color: Color(0xFF1B2B27),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showForm(null),
              icon: const Icon(Icons.add,
                  size: 16, color: Colors.white),
              label: const Text('Ajouter',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: bleu,
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
      body: _hospitalisations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital_outlined,
                      size: 80, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  const Text('Aucune hospitalisation',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B2B27))),
                  const SizedBox(height: 6),
                  Text(
                      "Ajoutez vos antécédents d'hospitalisation",
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _hospitalisations.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final h = _hospitalisations[i];
                final String hopital =
                    h['hopital']?.toString() ?? '';
                final String motif =
                    h['motif']?.toString() ?? '';
                final String entree =
                    h['dateEntree']?.toString() ?? '';
                final String sortie =
                    h['dateSortie']?.toString() ?? '';

                return InkWell(
                  onTap: () => _showForm(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                          color: bleu.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Icône
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: bleu.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons
                                  .local_hospital_outlined,
                              color: bleu,
                              size: 22),
                        ),
                        const SizedBox(width: 12),

                        // ✅ Contenu dans Expanded pour éviter l'overflow
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                hopital.isNotEmpty
                                    ? hopital
                                    : 'Hôpital non précisé',
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 15,
                                    color:
                                        Color(0xFF1B2B27)),
                              ),
                              if (motif.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(
                                          top: 3),
                                  child: Text(
                                    motif,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors
                                            .grey[500]),
                                  ),
                                ),
                              // ✅ Dates sur plusieurs lignes si nécessaire
                              if (entree.isNotEmpty ||
                                  sortie.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(
                                          top: 5),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (entree.isNotEmpty)
                                        Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .login_outlined,
                                                size: 12,
                                                color: bleu),
                                            const SizedBox(
                                                width: 3),
                                            Text(
                                                'Entrée : $entree',
                                                style: TextStyle(
                                                    fontSize:
                                                        11,
                                                    color: Colors
                                                        .grey[500])),
                                          ],
                                        ),
                                      if (sortie.isNotEmpty)
                                        Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .logout_outlined,
                                                size: 12,
                                                color: bleu),
                                            const SizedBox(
                                                width: 3),
                                            Text(
                                                'Sortie : $sortie',
                                                style: TextStyle(
                                                    fontSize:
                                                        11,
                                                    color: Colors
                                                        .grey[500])),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(),
                              icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20),
                              onPressed: () =>
                                  _supprimer(i),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey,
                                size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showForm(int? index) {
    final existing =
        index != null ? _hospitalisations[index] : null;
    final hopCtrl = TextEditingController(
        text: existing?['hopital']?.toString() ?? '');
    final motifCtrl = TextEditingController(
        text: existing?['motif']?.toString() ?? '');
    final entreeCtrl = TextEditingController(
        text: existing?['dateEntree']?.toString() ?? '');
    final sortieCtrl = TextEditingController(
        text: existing?['dateSortie']?.toString() ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom +
                  20),
          child: SingleChildScrollView(
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
                        borderRadius:
                            BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  index == null
                      ? 'Ajouter une hospitalisation'
                      : "Modifier l'hospitalisation",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 16),
                _HField(
                    ctrl: hopCtrl,
                    label: 'Hôpital',
                    icon: Icons.local_hospital_outlined),
                _HField(
                    ctrl: motifCtrl,
                    label: 'Motif',
                    icon: Icons.notes),
                _HField(
                    ctrl: entreeCtrl,
                    label: "Date d'entrée",
                    icon: Icons.login_outlined),
                _HField(
                    ctrl: sortieCtrl,
                    label: 'Date de sortie',
                    icon: Icons.logout_outlined),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: bleu,
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12))),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setLocal(
                                () => isSaving = true);
                            final entry = {
                              'hopital':
                                  hopCtrl.text.trim(),
                              'motif':
                                  motifCtrl.text.trim(),
                              'dateEntree':
                                  entreeCtrl.text.trim(),
                              'dateSortie':
                                  sortieCtrl.text.trim(),
                            };
                            setState(() {
                              if (index == null) {
                                _hospitalisations
                                    .add(entry);
                              } else {
                                _hospitalisations[index] =
                                    entry;
                              }
                            });
                            await _sauvegarder();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                        : const Text('Enregistrer',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold)),
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

  Future<void> _supprimer(int i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer'),
        content: const Text(
            'Supprimer cette hospitalisation ?'),
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
    setState(() => _hospitalisations.removeAt(i));
    await _sauvegarder();
  }
}

class _HField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  const _HField(
      {required this.ctrl,
      required this.label,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Colors.blue, width: 1.5),
          ),
        ),
      ),
    );
  }
}