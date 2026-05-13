import 'package:carnetdesante/services/database_service.dart';
import 'package:carnetdesante/views/home/add_consultation_stepper.dart';
import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> consultationData;

  const ConsultationDetailScreen({
    super.key,
    required this.docId,
    required this.consultationData,
  });

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState
    extends State<ConsultationDetailScreen> {
  static const Color primary = Color(0xFF1BC2AB);
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    _detailFuture =
        DatabaseService().getConsultationDetail(widget.docId);
  }

  Future<void> _openEdit(Map<String, dynamic> fullData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddConsultationStepper(
          docId: widget.docId,
          consultationData: fullData,
        ),
      ),
    );
    setState(() => _loadDetail());
  }

  // ✅ Suppression avec confirmation
  Future<void> _supprimerConsultation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la consultation'),
        content: const Text(
            'Voulez-vous vraiment supprimer cette consultation ? '
            'Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await DatabaseService().deleteConsultation(widget.docId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consultation supprimée'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pop(context); // ✅ retour à la liste
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B2B27)),
        title: const Text(
          'Détail Consultation',
          style: TextStyle(
            color: Color(0xFF1B2B27),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // ✅ Bouton supprimer dans l'AppBar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Supprimer',
            onPressed: _supprimerConsultation,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final data = snapshot.data ?? widget.consultationData;
          final List medicaments = data['medicaments'] ?? [];
          final List examens = data['examens'] ?? [];

          // ✅ Infos médecin
          final String medecinPrenom =
              data['medecinPrenom']?.toString() ?? '';
          final String medecinNom =
              data['medecinNom']?.toString() ?? '';
          final String medecinSpecialite =
              data['medecinSpecialite']?.toString() ?? '';
          final String medecinTel =
              data['medecinTel']?.toString() ?? '';
          final String medecinAdresse =
              data['medecinAdresse']?.toString() ?? '';

          final String medecinNomComplet =
              '$medecinPrenom $medecinNom'.trim();
          final bool hasMedecin = medecinNomComplet.isNotEmpty ||
              medecinSpecialite.isNotEmpty ||
              medecinTel.isNotEmpty ||
              medecinAdresse.isNotEmpty;

          return Scaffold(
            floatingActionButton: FloatingActionButton(
              heroTag: 'fab_detail',
              backgroundColor: primary,
              child: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _openEdit(data),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Informations générales ─────────────────
                  _SectionCard(
                    title: 'Informations',
                    icon: Icons.info_outline,
                    color: primary,
                    children: [
                      _InfoRow(
                          label: 'Date',
                          value: data['date'] ?? 'N/A'),
                      _InfoRow(
                          label: 'Motif',
                          value: data['motif'] ?? 'N/A'),
                      _InfoRow(
                          label: 'Diagnostic',
                          value: data['diagnostic'] ?? 'N/A'),
                      _InfoRow(
                          label: 'Observations',
                          value: data['observations'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Médecin ────────────────────────────────
                  if (hasMedecin)
                    _SectionCard(
                      title: 'Médecin',
                      icon: Icons.person_outline,
                      color: Colors.blue,
                      children: [
                        if (medecinNomComplet.isNotEmpty)
                          _InfoRow(
                            label: 'Nom',
                            value: medecinNomComplet
                                    .toLowerCase()
                                    .startsWith('dr')
                                ? medecinNomComplet
                                : 'Dr. $medecinNomComplet',
                          ),
                        if (medecinSpecialite.isNotEmpty)
                          _InfoRow(
                              label: 'Spécialité',
                              value: medecinSpecialite),
                        if (medecinTel.isNotEmpty)
                          _InfoRow(
                              label: 'Téléphone',
                              value: medecinTel),
                        if (medecinAdresse.isNotEmpty)
                          _InfoRow(
                              label: 'Cabinet',
                              value: medecinAdresse),
                      ],
                    ),
                  if (hasMedecin) const SizedBox(height: 12),

                  // ── Mesures ────────────────────────────────
                  _SectionCard(
                    title: 'Mesures cliniques',
                    icon: Icons.monitor_heart_outlined,
                    color: Colors.red,
                    children: [
                      _InfoRow(
                          label: 'Poids',
                          value: _val(data['poids'], 'kg')),
                      _InfoRow(
                          label: 'Taille',
                          value: _val(data['taille'], 'cm')),
                      _InfoRow(
                          label: 'Tension',
                          value: data['tension'] ?? 'N/A'),
                      _InfoRow(
                          label: 'Glycémie',
                          value: _val(data['glycemie'], 'mmol/L')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Ordonnance ─────────────────────────────
                  if ((data['photoOrdonnanceBase64'] ?? '')
                      .isNotEmpty) ...[
                    _SectionCard(
                      title: 'Ordonnance',
                      icon: Icons.receipt_long_outlined,
                      color: Colors.green,
                      children: [
                        _ClickablePhoto(
                          base64Image:
                              data['photoOrdonnanceBase64'],
                          title: 'Ordonnance',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Médicaments ────────────────────────────
                  _SectionCard(
                    title: 'Médicaments (${medicaments.length})',
                    icon: Icons.medication_outlined,
                    color: Colors.orange,
                    children: medicaments.isEmpty
                        ? [
                            Text('Aucun médicament',
                                style: TextStyle(
                                    color: Colors.grey[400]))
                          ]
                        : medicaments.map<Widget>((med) {
                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.04),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.orange
                                        .withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med['nom'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  if ((med['molecule'] ?? '')
                                      .isNotEmpty)
                                    _MedRow(
                                        label: 'Molécule',
                                        value: med['molecule']),
                                  if ((med['dosage'] ?? '')
                                      .isNotEmpty)
                                    _MedRow(
                                        label: 'Dosage',
                                        value: med['dosage']),
                                  if ((med['frequence'] ?? '')
                                      .isNotEmpty)
                                    _MedRow(
                                        label: 'Fréquence',
                                        value: med['frequence']),
                                  if ((med['duree'] ?? '')
                                      .isNotEmpty)
                                    _MedRow(
                                        label: 'Durée',
                                        value:
                                            '${med['duree']} jours'),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // ── Examens ────────────────────────────────
                  _SectionCard(
                    title: 'Examens (${examens.length})',
                    icon: Icons.biotech_outlined,
                    color: Colors.purple,
                    children: examens.isEmpty
                        ? [
                            Text('Aucun examen',
                                style: TextStyle(
                                    color: Colors.grey[400]))
                          ]
                        : examens.map<Widget>((ex) {
                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.04),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.purple
                                        .withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if ((ex['type'] ?? '').isNotEmpty)
                                    Text(
                                      ex['type'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  if ((ex['date'] ?? '').isNotEmpty)
                                    _MedRow(
                                        label: 'Date',
                                        value: ex['date']),
                                  if ((ex['photoExamenBase64'] ??
                                          '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _ClickablePhoto(
                                      base64Image:
                                          ex['photoExamenBase64'],
                                      title:
                                          "Examen : ${ex['type'] ?? ''}",
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _val(dynamic v, String unit) {
    if (v == null || v.toString().isEmpty) return 'N/A';
    return '$v $unit';
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête coloré
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                    color: color.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == 'N/A' || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500),
            ),
          ),
          const Text(' : ',
              style: TextStyle(
                  color: Colors.grey, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2B27)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Med Row ───────────────────────────────────────────────────────────────────
class _MedRow extends StatelessWidget {
  final String label;
  final String value;

  const _MedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: TextStyle(
                fontSize: 12, color: Colors.grey[500]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1B2B27)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo cliquable ───────────────────────────────────────────────────────────
class _ClickablePhoto extends StatelessWidget {
  final String base64Image;
  final String title;

  const _ClickablePhoto(
      {required this.base64Image, required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PhotoViewerScreen(
            base64Image: base64Image,
            title: title,
          ),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(base64Image),
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.zoom_in,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo Viewer ──────────────────────────────────────────────────────────────
class _PhotoViewerScreen extends StatefulWidget {
  final String base64Image;
  final String title;

  const _PhotoViewerScreen(
      {required this.base64Image, required this.title});

  @override
  State<_PhotoViewerScreen> createState() =>
      _PhotoViewerScreenState();
}

class _PhotoViewerScreenState
    extends State<_PhotoViewerScreen> {
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16)),
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
                  _scale =
                      _ctrl.value.getMaxScaleOnAxis()),
              child: Image.memory(
                base64Decode(widget.base64Image),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
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