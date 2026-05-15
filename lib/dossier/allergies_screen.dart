import 'package:carnetdesante/services/referentiel_service.dart';
import 'package:carnetdesante/widgets/suggestion_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllergiesScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> dossier;

  const AllergiesScreen(
      {super.key, required this.uid, required this.dossier});

  @override
  State<AllergiesScreen> createState() =>
      _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  // static const Color primary = Color(0xFF1BC2AB);
  late List<Map<String, dynamic>> _allergies;

  @override
  void initState() {
    super.initState();
    _allergies = List<Map<String, dynamic>>.from(
      (widget.dossier['allergies'] as List? ?? [])
          .map((a) => Map<String, dynamic>.from(a)),
    );
  }

  Future<void> _sauvegarder() async {
    await FirebaseFirestore.instance
        .collection('Dossier_Medical')
        .doc(widget.uid)
        .update({'allergies': _allergies});
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
        title: const Text('Allergies',
            style: TextStyle(
                color: Color(0xFF1B2B27),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _ajouter(),
              icon: const Icon(Icons.add,
                  size: 16, color: Colors.white),
              label: const Text('Ajouter',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
      body: _allergies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 70, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  const Text('Aucune allergie renseignée',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B2B27))),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _allergies.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = _allergies[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color:
                          Colors.orange.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.orange,
                        size: 20),
                  ),
                  title: Text(
                    a['nomAllergie'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1B2B27)),
                  ),
                  subtitle: (a['dateApparition'] ?? '')
                          .isNotEmpty
                      ? Text(
                          'Depuis : ${a['dateApparition']}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500]))
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: () async {
                      setState(
                          () => _allergies.removeAt(i));
                      await _sauvegarder();
                    },
                  ),
                  onTap: () => _modifier(i),
                );
              },
            ),
    );
  }

  void _ajouter() => _showForm(null);
  void _modifier(int i) => _showForm(i);

void _showForm(int? index) {
  final existing = index != null ? _allergies[index] : null;
  final nomCtrl = TextEditingController(
      text: existing?['nomAllergie']?.toString() ?? '');
  final dateCtrl = TextEditingController(
      text: existing?['dateApparition']?.toString() ?? '');
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
            Text(
              index == null
                  ? 'Ajouter une allergie'
                  : "Modifier l'allergie",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SuggestionField(
              label: "Nom de l'allergie",
              icon: Icons.warning_amber_outlined,
              color: Colors.orange,
              collection: 'AllergiesRef',
              displayField: 'nomAllergie',
              controller: nomCtrl,
              selectedData: {},
              suggestionsLocales: ReferentielService.allergiesPredefines,
              onSelected: (data) {
                nomCtrl.text = data['nomAllergie'] ?? '';
              },
              showAutre: true,
              onAutre: () => nomCtrl.clear(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              decoration: InputDecoration(
                labelText: "Date d'apparition (optionnel)",
                prefixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.orange),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.orange, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12))),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nomCtrl.text.trim().isEmpty)
                          return;
                        setLocal(() => isSaving = true);
                        final entry = {
                          'nomAllergie': nomCtrl.text.trim(),
                          'dateApparition':
                              dateCtrl.text.trim(),
                        };
                        setState(() {
                          if (index == null) {
                            _allergies.add(entry);
                          } else {
                            _allergies[index] = entry;
                          }
                        });
                        await _sauvegarder();
                        await ReferentielService
                            .sauvegarderAllergie(
                                nomCtrl.text.trim());
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
                    : const Text('Enregistrer',
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
}