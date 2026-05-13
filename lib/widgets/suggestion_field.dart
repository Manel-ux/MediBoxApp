import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Widget générique : TextField avec liste de suggestions Firestore
class SuggestionField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String collection;      // collection Firestore
  final String displayField;    // champ à afficher dans la liste
  final TextEditingController controller;
  final Map<String, dynamic> selectedData; // données complètes du choix
  final ValueChanged<Map<String, dynamic>>? onSelected;
  final VoidCallback? onAutre;  // appelé si l'utilisateur clique "Autre"
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
      _suggestions = snap.docs
          .map((d) => {'_id': d.id, ...d.data()})
          .where((d) =>
              (d[widget.displayField]?.toString() ?? '')
                  .toLowerCase()
                  .contains(q))
          .take(6)
          .toList();

      setState(() {
        _showList = true;
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
              borderSide:
                  BorderSide(color: widget.color, width: 1.5),
            ),
          ),
        ),

        // Liste de suggestions
        if (_showList && (_suggestions.isNotEmpty || widget.showAutre))
          Container(
            margin: const EdgeInsets.only(top: 4),
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
            child: Column(
              children: [
                // Suggestions existantes
                ..._suggestions.map((item) => InkWell(
                      onTap: () {
                        widget.controller.text =
                            item[widget.displayField]
                                ?.toString() ??
                                '';
                        setState(() => _showList = false);
                        widget.onSelected?.call(item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(widget.icon,
                                color: widget.color, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item[widget.displayField]
                                        ?.toString() ??
                                    '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w500),
                              ),
                            ),
                            Icon(Icons.north_west,
                                size: 14,
                                color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    )),

                // Divider si suggestions + Autre
                if (_suggestions.isNotEmpty && widget.showAutre)
                  const Divider(height: 1),

                // Option "Autre"
                if (widget.showAutre)
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
            ),
          ),
      ],
    );
  }
}