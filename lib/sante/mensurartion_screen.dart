import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MensurationsScreen extends StatefulWidget {
  const MensurationsScreen({super.key});

  @override
  State<MensurationsScreen> createState() =>
      _MensurationsScreenState();
}

class _MensurationsScreenState extends State<MensurationsScreen> {
  static const Color primary = Color(0xFF1BC2AB);
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _mensurations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> all = [];

      // ✅ 1. Mensurations manuelles
      final manuSnap = await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(uid)
          .collection('Mensurations')
          .get()
          .timeout(const Duration(seconds: 8));

      for (var d in manuSnap.docs) {
        all.add({
          ...d.data(),
          '_id': d.id,
          'source': d.data()['source'] ?? 'manuel',
        });
      }

      // ✅ 2. Mensurations depuis les consultations
      final consultSnap = await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(uid)
          .collection('Consultations')
          .get()
          .timeout(const Duration(seconds: 8));

      for (var consult in consultSnap.docs) {
        final data = consult.data();
        // Vérifie si au moins une mesure existe
        final bool hasMesure = [
          data['poids'],
          data['tension'],
          data['taille'],
          data['glycemie'],
        ].any((v) => v != null && v.toString().isNotEmpty);

        if (hasMesure) {
          all.add({
            'date': data['date'] ?? '',
            'poids': data['poids'] ?? '',
            'tension': data['tension'] ?? '',
            'taille': data['taille'] ?? '',
            'glycemie': data['glycemie'] ?? '',
            'source': 'consultation',
            'sourceMotif': data['motif'] ?? '',
            '_id': consult.id,
            '_timestamp': data['timestamp'],
          });
        }
      }

      // ✅ Tri par date décroissante
      all.sort((a, b) {
        final ta = a['_timestamp'] as Timestamp?;
        final tb = b['_timestamp'] as Timestamp?;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

      setState(() {
        _mensurations = all;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur mensurations : $e');
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
        iconTheme: const IconThemeData(color: Color(0xFF1B2B27)),
        title: const Text('Mes Mensurations',
            style: TextStyle(
                color: Color(0xFF1B2B27),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showAddMensuration(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Ajouter',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              color: primary,
              child: _mensurations.isEmpty
                  ? ListView(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monitor_heart_outlined, size: 80, color: Colors.grey[200]),
                              const SizedBox(height: 16),
                              const Text('Aucune mensuration', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B2B27))),
                              const SizedBox(height: 6),
                              Text('Ajoutez votre première mesure', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _mensurations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, i) {
                        final data = _mensurations[i];
                        final String source = data['source']?.toString() ?? 'manuel';
                        final String date = data['date']?.toString() ?? '';
                        final String motif = data['sourceMotif']?.toString() ?? '';

                        final Color color = source == 'consultation' ? primary : Colors.purple;
                        final IconData icon = source == 'consultation'
                            ? Icons.medical_services_outlined
                            : Icons.edit_outlined;
                        final String sourceLabel = source == 'consultation'
                            ? (motif.isNotEmpty ? 'Consultation : $motif' : 'Depuis une consultation')
                            : 'Saisie manuelle';

                        return InkWell(
                          onTap: () => _showDetail(context, data),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8, runSpacing: 4,
                                        children: [
                                          if ((data['poids']?.toString() ?? '').isNotEmpty)
                                            _MetriqueBadge(label: 'Poids', value: '${data['poids']} kg', color: primary),
                                          if ((data['tension']?.toString() ?? '').isNotEmpty)
                                            _MetriqueBadge(label: 'Tension', value: data['tension'].toString(), color: Colors.red),
                                          if ((data['taille']?.toString() ?? '').isNotEmpty)
                                            _MetriqueBadge(label: 'Taille', value: '${data['taille']} cm', color: Colors.blue),
                                          if ((data['glycemie']?.toString() ?? '').isNotEmpty)
                                            _MetriqueBadge(label: 'Glycémie', value: '${data['glycemie']} g/L', color: Colors.orange),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Icon(icon, size: 11, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(sourceLabel,
                                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DetailMensuration(data: data, uid: uid, onDelete: data['source'] == 'manuel'
          ? () async {
              await FirebaseFirestore.instance
                  .collection('Dossier_Medical')
                  .doc(uid)
                  .collection('Mensurations')
                  .doc(data['_id'])
                  .delete();
              _charger();
            }
          : null), // ✅ pas de suppression pour les mensurations issues des consultations
    );
  }

  void _showAddMensuration(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMensuration(uid: uid),
    );
    if (result == true && mounted) _charger();
  }
}

// ── Détail mensuration ────────────────────────────────────────────────────────
class _DetailMensuration extends StatelessWidget {
  final Map<String, dynamic> data;
  final String uid;
  final VoidCallback? onDelete; // ✅ optionnel

  const _DetailMensuration(
      {required this.data,
      required this.uid,
      this.onDelete});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1BC2AB);
    final String source = data['source']?.toString() ?? 'manuel';
    final String motif = data['sourceMotif']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['date'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              // ✅ Suppression uniquement pour les saisies manuelles
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    onDelete!();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Row(label: 'Poids', value: '${data['poids'] ?? 'N/A'} kg'),
          _Row(label: 'Taille', value: '${data['taille'] ?? 'N/A'} cm'),
          _Row(label: 'Tension', value: data['tension']?.toString() ?? 'N/A'),
          _Row(label: 'Glycémie', value: '${data['glycemie'] ?? 'N/A'} g/L'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (source == 'consultation' ? primary : Colors.purple).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(
                source == 'consultation' ? Icons.medical_services_outlined : Icons.person_outline,
                size: 14,
                color: source == 'consultation' ? primary : Colors.purple,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  source == 'consultation'
                      ? (motif.isNotEmpty ? 'Issue de la consultation : $motif' : 'Issue d\'une consultation')
                      : 'Saisie manuelle',
                  style: TextStyle(
                    color: source == 'consultation' ? primary : Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == 'N/A' || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 13)),
          ),
          const Text(' : '),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1B2B27))),
        ],
      ),
    );
  }
}

// ── Ajouter mensuration ───────────────────────────────────────────────────────
class _AddMensuration extends StatefulWidget {
  final String uid;
  const _AddMensuration({required this.uid});

  @override
  State<_AddMensuration> createState() =>
      _AddMensurationState();
}

class _AddMensurationState extends State<_AddMensuration> {
  static const Color primary = Color(0xFF1BC2AB);
  final _poidsCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _tensionCtrl = TextEditingController();
  final _glycemieCtrl = TextEditingController();
  bool _isSaving = false;
  String _date = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void dispose() {
    _poidsCtrl.dispose();
    _tailleCtrl.dispose();
    _tensionCtrl.dispose();
    _glycemieCtrl.dispose();
    super.dispose();
  }

Future<void> _sauvegarder() async {
  setState(() => _isSaving = true);
  try {
    await FirebaseFirestore.instance
        .collection('Dossier_Medical')
        .doc(widget.uid)
        .collection('Mensurations')
        .add({
      'date': _date,
      'poids': _poidsCtrl.text.trim(),
      'taille': _tailleCtrl.text.trim(),
      'tension': _tensionCtrl.text.trim(),
      'glycemie': _glycemieCtrl.text.trim(),
      'source': 'manuel',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    Navigator.pop(context, true); // ✅ retourne true
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Mensuration ajoutée !'),
          backgroundColor: Color(0xFF1BC2AB)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $e'),
          backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(context).viewInsets.bottom + 24),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nouvelle mensuration',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text('Date : $_date',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),
            _MField(ctrl: _poidsCtrl,
                label: 'Poids (kg)',
                icon: Icons.monitor_weight_outlined,
                isNum: true),
            _MField(ctrl: _tailleCtrl,
                label: 'Taille (cm)',
                icon: Icons.height,
                isNum: true),
            _MField(ctrl: _tensionCtrl,
                label: 'Tension (ex: 12/8)',
                icon: Icons.favorite_outline),
            _MField(ctrl: _glycemieCtrl,
                label: 'Glycémie (g/L)',
                icon: Icons.water_drop_outlined,
                isNum: true),
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
                onPressed: _isSaving ? null : _sauvegarder,
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Text('Enregistrer',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _MetriqueBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetriqueBadge(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text('$label : $value',
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _MField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isNum;
  const _MField(
      {required this.ctrl,
      required this.label,
      required this.icon,
      this.isNum = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType:
            isNum ? TextInputType.number : TextInputType.text,
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