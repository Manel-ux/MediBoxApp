import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuggestionField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String collection;
  final String displayField;
  final TextEditingController controller;
  final Map<String, dynamic> selectedData;
  final ValueChanged<Map<String, dynamic>>? onSelected;
  final VoidCallback? onAutre;
  final bool showAutre;
  final List<String>? suggestionsLocales;
  final List<Map<String, String>>? suggestionsLocalesMap;

  const SuggestionField({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.collection,
    required this.displayField,
    required this.controller,
    required this.selectedData,
    this.onSelected,
    this.onAutre,
    this.showAutre = true,
    this.suggestionsLocales,
    this.suggestionsLocalesMap,
  });

  @override
  State<SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<SuggestionField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _showList = false;
  bool _loading = false;

  // ✅ Helper : fusionne Firestore + locales String
  List<Map<String, dynamic>> _fusionnerLocalesString(
    List<Map<String, dynamic>> firestoreDocs,
    int maxTotal,
  ) {
    if (widget.suggestionsLocales == null) return [];
    final firestoreNoms = firestoreDocs
        .map((d) => d[widget.displayField]?.toString().toLowerCase() ?? '')
        .toSet();
    return widget.suggestionsLocales!
        .where((s) => !firestoreNoms.contains(s.toLowerCase()))
        .take((maxTotal - firestoreDocs.length).clamp(0, maxTotal))
        .map((s) => {
              '_id': '',
              '_local': true,
              widget.displayField: s,
            })
        .toList();
  }

  // ✅ Helper : fusionne Firestore + locales Map (médicaments)
  List<Map<String, dynamic>> _fusionnerLocalesMap(
    List<Map<String, dynamic>> firestoreDocs,
    int maxTotal, {
    String filtreQuery = '',
  }) {
    if (widget.suggestionsLocalesMap == null) return [];
    final firestoreNoms = firestoreDocs
        .map((d) => d['nom']?.toString().toLowerCase() ?? '')
        .toSet();
    return widget.suggestionsLocalesMap!
        .where((m) {
          if (filtreQuery.isEmpty) return true;
          final q = filtreQuery.toLowerCase();
          return (m['nom'] ?? '').toLowerCase().contains(q) ||
              (m['molecule'] ?? '').toLowerCase().contains(q);
        })
        .where((m) =>
            !firestoreNoms.contains((m['nom'] ?? '').toLowerCase()))
        .take((maxTotal - firestoreDocs.length).clamp(0, maxTotal))
        .map((m) => {
              '_id': '',
              '_local': true,
              'nom': m['nom'] ?? '',
              'molecule': m['molecule'] ?? '',
              'dosage': m['dosage'] ?? '',
              widget.displayField: m['nom'] ?? '',
            })
        .toList();
  }

  Future<void> _chargerSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showList = false;
        _suggestions = [];
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(widget.collection)
          .get()
          .timeout(const Duration(seconds: 5));

      final q = query.toLowerCase();

      // 1. Firestore filtré
      final firestoreDocs = snap.docs
          .map((d) => {'_id': d.id, ...d.data()})
          .where((d) => d.values.any(
              (v) => v?.toString().toLowerCase().contains(q) ?? false))
          .toList();

      final List<Map<String, dynamic>> resultats = [...firestoreDocs];

      // 2. Locales Map (médicaments)
      resultats.addAll(
          _fusionnerLocalesMap(firestoreDocs, 10, filtreQuery: query));

      // 3. Locales String (allergies / maladies / examens)
      resultats.addAll(_fusionnerLocalesString(firestoreDocs, 10)
          .where((item) =>
              (item[widget.displayField] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q))
          .toList());

      setState(() {
        _suggestions = resultats.take(10).toList();
        _showList = true;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur suggestions : $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _chargerTout() async {
    setState(() => _loading = true);
    try {
      // 1. Firestore
      final snap = await FirebaseFirestore.instance
          .collection(widget.collection)
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 5));

      final firestoreDocs =
          snap.docs.map((d) => {'_id': d.id, ...d.data()}).toList();

      final List<Map<String, dynamic>> resultats = [...firestoreDocs];

      // 2. Locales Map (médicaments)
      resultats.addAll(_fusionnerLocalesMap(firestoreDocs, 10));

      // 3. Locales String (allergies / maladies / examens)
      resultats.addAll(_fusionnerLocalesString(firestoreDocs, 10));

      setState(() {
        _suggestions = resultats.take(10).toList();
        _showList = resultats.isNotEmpty || widget.showAutre;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _chargerSuggestions,
          onTap: () {
            if (widget.controller.text.isEmpty) _chargerTout();
          },
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon, color: widget.color),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _showList = false;
                        _suggestions = [];
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.color, width: 1.5),
            ),
          ),
        ),

        if (_showList)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      ..._suggestions.map((item) {
                        final bool isLocal = item['_local'] == true;
                        final String texte =
                            item[widget.displayField]?.toString() ?? '';
                        final String sousTitre = _buildSousTitre(item);

                        return InkWell(
                          onTap: () {
                            widget.controller.text = texte;
                            setState(() => _showList = false);
                            widget.onSelected?.call(item);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[100]!, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(widget.icon,
                                    color: isLocal
                                        ? widget.color.withOpacity(0.5)
                                        : widget.color,
                                    size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(texte,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      if (sousTitre.isNotEmpty)
                                        Text(sousTitre,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                                if (isLocal)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          widget.color.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text('Suggestion',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: widget.color,
                                            fontWeight:
                                                FontWeight.w600)),
                                  )
                                else
                                  Icon(Icons.north_west,
                                      size: 14,
                                      color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        );
                      }),

                      if (widget.showAutre) ...[
                        if (_suggestions.isNotEmpty)
                          Divider(height: 1, color: Colors.grey[200]),
                        InkWell(
                          onTap: () {
                            setState(() => _showList = false);
                            widget.onAutre?.call();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline,
                                    color: widget.color, size: 18),
                                const SizedBox(width: 12),
                                Text(
                                  'Autre (saisir manuellement)',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: widget.color,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _buildSousTitre(Map<String, dynamic> item) {
    final List<String> parts = [];
    final specialite = item['specialite']?.toString() ?? '';
    if (specialite.isNotEmpty) parts.add(specialite);
    final molecule = item['molecule']?.toString() ?? '';
    if (molecule.isNotEmpty) parts.add(molecule);
    final dosage = item['dosage']?.toString() ?? '';
    if (dosage.isNotEmpty) parts.add(dosage);
    return parts.join(' • ');
  }
}