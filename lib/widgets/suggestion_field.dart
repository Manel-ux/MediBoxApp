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
  });

  @override
  State<SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<SuggestionField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _showList = false;
  bool _loading = false;

  Future<void> _chargerSuggestions(String query) async {
    // ✅ Affiche la liste dès la première lettre
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

      // ✅ Filtre sur TOUS les champs du document, pas seulement displayField
      _suggestions = snap.docs.map((d) => {'_id': d.id, ...d.data()}).where((d) {
        // Cherche dans tous les champs string du document
        return d.values.any((v) =>
            v?.toString().toLowerCase().contains(q) ?? false);
      }).take(8).toList();

      setState(() {
        _showList = true;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur suggestions : $e');
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

        // ✅ Liste déroulante
        if (_showList)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 250),
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
                    // ✅ Résultats trouvés
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_suggestions.isEmpty && !widget.showAutre)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Aucun résultat — vous pouvez saisir manuellement',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 13),
                        ),
                      )
                    else
                      ..._suggestions.map((item) => InkWell(
                            onTap: () {
                              widget.controller.text =
                                  item[widget.displayField]?.toString() ?? '';
                              setState(() => _showList = false);
                              widget.onSelected?.call(item);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey[100]!, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(widget.icon,
                                      color: widget.color, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item[widget.displayField]
                                                  ?.toString() ??
                                              '',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        // ✅ Sous-titre avec infos supplémentaires
                                        if (_buildSousTitre(item).isNotEmpty)
                                          Text(
                                            _buildSousTitre(item),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500]),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.north_west,
                                      size: 14, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          )),

                    // ✅ Option "Autre / Nouveau"
                    if (widget.showAutre) ...[
                      if (_suggestions.isNotEmpty)
                        Divider(height: 1, color: Colors.grey[200]),
                      InkWell(
                        onTap: () {
                          setState(() => _showList = false);
                          widget.onAutre?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: widget.color, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                '+ Nouveau (saisir manuellement)',
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
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ✅ Construit un sous-titre selon le type de collection
  String _buildSousTitre(Map<String, dynamic> item) {
  final List<String> parts = [];

  final specialite = item['specialite']?.toString() ?? '';
  if (specialite.isNotEmpty) parts.add(specialite);

  final molecule = item['molecule']?.toString() ?? '';
  if (molecule.isNotEmpty) parts.add(molecule);

  final dosage = item['dosage']?.toString() ?? '';
  if (dosage.isNotEmpty) parts.add(dosage);

  // ✅ Correction : deux conditions séparées
  final prenom = item['prenom']?.toString() ?? '';
  final nom = item['nom']?.toString() ?? '';
  if (prenom.isNotEmpty && nom.isNotEmpty) {
    parts.add('$prenom $nom');
  }

  return parts.join(' • ');
}
}