import 'dart:convert';
// import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

class DocumentsScreen extends StatefulWidget {
  final String uid;
  const DocumentsScreen({super.key, required this.uid});

  @override
  State<DocumentsScreen> createState() =>
      _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  // static const Color primary = Color(0xFF1BC2AB);
  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> docs = [];

      // ✅ 1. Charge les documents manuels
      final manuelsSnap = await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(widget.uid)
          .collection('Documents')
          .get()
          .timeout(const Duration(seconds: 8));

      for (var d in manuelsSnap.docs) {
        docs.add({
          ...d.data(),
          '_docId': d.id,
          '_collection': 'Documents',
        });
      }

      // ✅ 2. Charge les consultations
      final consultSnap = await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(widget.uid)
          .collection('Consultations')
          .get()
          .timeout(const Duration(seconds: 8));

      for (var consult in consultSnap.docs) {
        final consultData = consult.data();
        final String dateConsult =
            consultData['date']?.toString() ?? '';
        final String motif =
            consultData['motif']?.toString() ?? '';

        // ✅ 2a. Ordonnance (stockée dans le document consultation)
        final String? ordBase64 =
            consultData['photoOrdonnanceBase64']
                ?.toString();
        if (ordBase64 != null && ordBase64.isNotEmpty) {
          docs.add({
            'type': 'ordonnance',
            'sousType': '',
            'titre': 'Ordonnance',
            'source': motif.isNotEmpty
                ? 'Consultation : $motif ($dateConsult)'
                : 'Consultation du $dateConsult',
            'imageBase64': ordBase64,
            '_docId': consult.id,
            '_collection': 'consultation_ordonnance',
            '_date': consultData['timestamp'],
          });
        }

        // ✅ 2b. Examens (sous-collection Examens)
        final examensSnap = await consult.reference
            .collection('Examens')
            .get()
            .timeout(const Duration(seconds: 8));

        for (var examen in examensSnap.docs) {
          final exData = examen.data();
          final String? exBase64 =
              exData['photoExamenBase64']?.toString();
          final String typeExamen =
              exData['type']?.toString() ?? 'Examen';

          docs.add({
            'type': 'examen',
            'sousType': typeExamen,
            'titre': typeExamen.isNotEmpty
                ? 'Examen : $typeExamen'
                : 'Examen médical',
            'source': motif.isNotEmpty
                ? 'Consultation : $motif ($dateConsult)'
                : 'Consultation du $dateConsult',
            'imageBase64': exBase64 ?? '',
            '_docId': examen.id,
            '_collection': 'consultation_examen',
            '_date': consultData['timestamp'],
          });
        }
      }

      // ✅ Tri par date décroissante
      docs.sort((a, b) {
        final da = a['_date'] as Timestamp?;
        final db = b['_date'] as Timestamp?;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      setState(() {
        _documents = docs;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement documents : $e');
      setState(() => _loading = false);
    }
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
        title: const Text('Documents médicaux',
            style: TextStyle(
                color: Color(0xFF1B2B27),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Color(0xFF1BC2AB)),
            onPressed: _charger,
          ),
        ],
      ),
      
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              color: const Color(0xFF1BC2AB),
              // ✅ Après _loading check, avant la liste
              child: Column(
                children: [
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher (titre, type, consultation...)',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // Liste filtrée
                  Expanded(
                    child: Builder(builder: (context) {
                      var filtered = _documents;
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        filtered = _documents.where((d) {
                          return (d['titre']?.toString() ?? '').toLowerCase().contains(q) ||
                                (d['type']?.toString() ?? '').toLowerCase().contains(q) ||
                                (d['sousType']?.toString() ?? '').toLowerCase().contains(q) ||
                                (d['source']?.toString() ?? '').toLowerCase().contains(q);
                        }).toList();
                      }
                    return filtered.isEmpty
              
                    ? ListView(
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height *
                                  0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_outlined,
                                    size: 80,
                                    color: Colors.grey[200]),
                                const SizedBox(height: 16),
                                const Text('Aucun document',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(
                                            0xFF1B2B27))),
                                const SizedBox(height: 6),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 40),
                                  child: Text(
                                    'Vos ordonnances et examens '
                                    'issus de vos consultations '
                                    'apparaîtront ici.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16),
                      itemBuilder: (context, i) {
                        final data = filtered[i];
                        final String type =
                            data['type']?.toString() ??
                                'document';
                        final String sousType =
                            data['sousType']?.toString() ?? '';
                        final String titre =
                            data['titre']?.toString() ?? '';
                        final String source =
                            data['source']?.toString() ?? '';
                        final bool hasImage =
                            (data['imageBase64'] ?? '')
                                .isNotEmpty;

                        final Color color =
                            type == 'ordonnance'
                                ? Colors.green
                                : Colors.blue;
                        final IconData icon =
                            type == 'ordonnance'
                                ? Icons.receipt_long_outlined
                                : Icons.biotech_outlined;

                        final String titreAffiche =
                            titre.isNotEmpty
                                ? titre
                                : type == 'ordonnance'
                                    ? 'Ordonnance'
                                    : sousType.isNotEmpty
                                        ? 'Examen : $sousType'
                                        : 'Examen médical';

                        return InkWell(
                          onTap: () => hasImage
                              ? _voirDocument(
                                  context, data, '')
                              : ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Aucune image pour ce document'),
                                )),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(
                                    color:
                                        color.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                  ),
                                  child: Icon(icon,
                                      color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(titreAffiche,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                              fontSize: 14,
                                              color: Color(
                                                  0xFF1B2B27))),
                                      const SizedBox(height: 3),
                                      // Badge type
                                      Row(children: [
                                        Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 7,
                                                  vertical: 2),
                                          decoration:
                                              BoxDecoration(
                                            color: color
                                                .withOpacity(
                                                    0.1),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(4),
                                          ),
                                          child: Text(
                                            type == 'ordonnance'
                                                ? 'Ordonnance'
                                                : 'Examen',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: color,
                                                fontWeight:
                                                    FontWeight
                                                        .w600),
                                          ),
                                        ),
                                        if (!hasImage) ...[
                                          const SizedBox(
                                              width: 6),
                                          Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 12,
                                              color: Colors
                                                  .grey[400]),
                                        ],
                                      ]),
                                      // Source
                                      if (source.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .only(top: 3),
                                          child: Text(source,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors
                                                      .grey[500]),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis),
                                        ),
                                    ],
                                  ),
                                ),
                                if (hasImage)
                                  const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 18)
                                else
                                  Icon(
                                      Icons
                                          .block_outlined,
                                      color: Colors.grey[300],
                                      size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    );
 }),
                  ),
                ],
              ),
          ));
  }

  void _voirDocument(BuildContext context,
      Map<String, dynamic> data, String docId) {
    final String? base64 =
        data['imageBase64']?.toString();
    if (base64 == null || base64.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DocumentViewer(
          base64Image: base64,
          titre: data['titre']?.toString() ?? 'Document',
        ),
      ),
    );
  }
}

// ── Viewer document ───────────────────────────────────────────────────────────
class _DocumentViewer extends StatefulWidget {
  final String base64Image;
  final String titre;
  const _DocumentViewer(
      {required this.base64Image, required this.titre});

  @override
  State<_DocumentViewer> createState() =>
      _DocumentViewerState();
}

class _DocumentViewerState extends State<_DocumentViewer> {
  final TransformationController _ctrl =
      TransformationController();
  double _scale = 1.0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme:
            const IconThemeData(color: Colors.white),
        title: Text(widget.titre,
            style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map,
                color: Colors.white),
            onPressed: () {
              _ctrl.value = Matrix4.identity();
              setState(() => _scale = 1.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              transformationController: _ctrl,
              minScale: 0.5,
              maxScale: 5.0,
              onInteractionUpdate: (d) => setState(() =>
                  _scale = _ctrl.value.getMaxScaleOnAxis()),
              child: Image.memory(
                base64Decode(widget.base64Image),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Zoom : x${_scale.toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}