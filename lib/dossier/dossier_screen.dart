import 'package:carnetdesante/dossier/allergies_screen.dart';
import 'package:carnetdesante/dossier/documents_screen.dart';
import 'package:carnetdesante/dossier/hospitalisation_screen.dart';
import 'package:carnetdesante/dossier/maladies_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DossierScreen extends StatefulWidget {
  const DossierScreen({super.key});

  @override
  State<DossierScreen> createState() => _DossierScreenState();
}

class _DossierScreenState extends State<DossierScreen> {
  static const Color primary = Color(0xFF1BC2AB);
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic> _dossier = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

Future<void> _charger() async {
  setState(() => _loading = true);
  try {
    // ✅ Essaie d'abord le cache, sinon réseau
    DocumentSnapshot? snap;
    try {
      snap = await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
    } catch (_) {
      // Cache vide → charge depuis le réseau
    }
    snap ??= await FirebaseFirestore.instance
        .collection('Dossier_Medical')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 8));

    _dossier = snap.data() as Map<String, dynamic>? ?? {};
  } catch (e) {
    debugPrint('Erreur dossier : $e');
    _dossier = {};
  }
  if (mounted) setState(() => _loading = false);
}

  // ✅ Extrait le sous-titre hospitalisation sans crash
  String _hospitalisationSubtitle() {
    final raw = _dossier['hospitalisation'];
    if (raw == null) return 'Non renseigné';

    try {
      // Format liste
      if (raw is List) {
        if (raw.isEmpty) return 'Non renseigné';
        final first = Map<String, dynamic>.from(raw[0] as Map);
        final h = first['hopital']?.toString() ?? '';
        return h.isNotEmpty
            ? '$h (${raw.length} entrée${raw.length > 1 ? 's' : ''})'
            : '${raw.length} entrée${raw.length > 1 ? 's' : ''}';
      }

      // Format Map indexé {"0": {...}, "1": {...}}
      if (raw is Map) {
        final keys = raw.keys.toList();
        final isIndexed =
            keys.every((k) => int.tryParse(k.toString()) != null);

        if (isIndexed) {
          if (keys.isEmpty) return 'Non renseigné';
          final first = Map<String, dynamic>.from(
              raw[keys.first] as Map);
          final h = first['hopital']?.toString() ?? '';
          return h.isNotEmpty
              ? '$h (${keys.length} entrée${keys.length > 1 ? 's' : ''})'
              : '${keys.length} entrée${keys.length > 1 ? 's' : ''}';
        }

        // Format objet unique {"hopital": "ehu", ...}
        final h = raw['hopital']?.toString() ?? '';
        return h.isNotEmpty ? h : 'Renseigné';
      }
    } catch (e) {
      debugPrint('Erreur hospitalisation subtitle: $e');
    }

    return 'Renseigné';
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
        title: const Text('Mon Dossier Médical',
            style: TextStyle(
                color: Color(0xFF1B2B27),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Groupe sanguin ────────────────
                    _DossierTile(
                      icon: Icons.bloodtype_outlined,
                      color: Colors.red,
                      title: 'Groupe sanguin',
                      subtitle: (_dossier['groupeSanguin']
                                  ?.toString() ??
                              '')
                          .isNotEmpty
                          ? _dossier['groupeSanguin']
                              .toString()
                          : 'Non renseigné',
                      onTap: () => _editGroupeSanguin(),
                    ),
                    const SizedBox(height: 12),

                    // ── Allergies ─────────────────────
                    _DossierTile(
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                      title: 'Allergies',
                      subtitle: _countLabel(
                          _dossier['allergies'], 'allergie'),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllergiesScreen(
                                uid: uid,
                                dossier: _dossier),
                          ),
                        );
                        _charger();
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Maladies chroniques ───────────
                    _DossierTile(
                      icon: Icons.healing_outlined,
                      color: primary,
                      title: 'Maladies chroniques',
                      subtitle: _countLabel(
                          _dossier['maladies'], 'maladie'),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaladiesScreen(
                                uid: uid,
                                dossier: _dossier),
                          ),
                        );
                        _charger();
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Hospitalisation ───────────────
                    _DossierTile(
                      icon: Icons.local_hospital_outlined,
                      color: Colors.blue,
                      title: 'Hospitalisation',
                      // ✅ Utilise la méthode sécurisée
                      subtitle: _hospitalisationSubtitle(),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HospitalisationScreen(
                                    uid: uid,
                                    dossier: _dossier),
                          ),
                        );
                        _charger();
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Documents médicaux ────────────
                    _DossierTile(
                      icon: Icons.folder_outlined,
                      color: Colors.purple,
                      title: 'Documents médicaux',
                      subtitle:
                          'Ordonnances, examens, résultats...',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DocumentsScreen(uid: uid),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _countLabel(dynamic list, String mot) {
    final l = list as List? ?? [];
    if (l.isEmpty) return 'Aucun(e)';
    return '${l.length} $mot${l.length > 1 ? 's' : ''}';
  }

  void _editGroupeSanguin() {
    String? selected =
        _dossier['groupeSanguin']?.toString();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(20),
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
              const Text('Groupe sanguin',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  'A+', 'A-', 'B+', 'B-',
                  'AB+', 'AB-', 'O+', 'O-'
                ].map((g) {
                  final bool sel = selected == g;
                  return GestureDetector(
                    onTap: () =>
                        setLocal(() => selected = g),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? primary
                            : Colors.grey[100],
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(g,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sel
                                  ? Colors.white
                                  : Colors.grey[700])),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14)),
                  onPressed: () async {
                    if (selected == null) return;
                    await FirebaseFirestore.instance
                        .collection('Dossier_Medical')
                        .doc(uid)
                        .update(
                            {'groupeSanguin': selected});
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _charger();
                    }
                  },
                  child: const Text('Enregistrer',
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

class _DossierTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DossierTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1B2B27))),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.grey),
          ],
        ),
      ),
    );
  }
}