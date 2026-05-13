// ignore_for_file: prefer_final_fields, curly_braces_in_flow_control_structures, unnecessary_underscores

import 'package:carnetdesante/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════
class RappelsScreen extends StatefulWidget {
  const RappelsScreen({super.key});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends State<RappelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color primary = Color(0xFF1BC2AB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rappels',
          style: TextStyle(
            color: Color(0xFF1B2B27),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        // ✅ Switch Médicaments / Rendez-vous dans l'appBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      // ── Médicaments ──
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: _tabController.index == 0
                                  ? [const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 16,
                                  color: _tabController.index == 0
                                      ? primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Médicaments',
                                  style: TextStyle(
                                    fontWeight: _tabController.index == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: _tabController.index == 0
                                        ? primary
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Rendez-vous ──
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: _tabController.index == 1
                                  ? [const BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: _tabController.index == 1
                                      ? primary
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Rendez-vous',
                                  style: TextStyle(
                                    fontWeight: _tabController.index == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: _tabController.index == 1
                                        ? primary
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // ✅ pas de swipe
        children: const [
          _MedicamentsRappelsTab(),
          _RendezVousRappelsTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — MÉDICAMENTS
// ══════════════════════════════════════════════════════════════════════════════
class _MedicamentsRappelsTab extends StatefulWidget {
  const _MedicamentsRappelsTab();

  @override
  State<_MedicamentsRappelsTab> createState() =>
      _MedicamentsRappelsTabState();
}

class _MedicamentsRappelsTabState extends State<_MedicamentsRappelsTab> {
  static const Color primary = Color(0xFF1BC2AB);
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String _searchQuery = '';
  final Set<String> _selected = {};
  bool _selectionMode = false;

  Stream<QuerySnapshot> get _rappelsStream => FirebaseFirestore.instance
      .collection('Rappels')
      .doc(uid)
      .collection('Medicaments')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Barre recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
              ),
            ),
          ),

          // Barre sélection multiple
          if (_selectionMode)
            Container(
              color: primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    '${_selected.length} sélectionné(s)',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _supprimerSelection,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label: const Text('Supprimer',
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectionMode = false;
                      _selected.clear();
                    }),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),

          // Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _rappelsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                var docs = snapshot.data?.docs ?? [];

                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data =
                        d.data() as Map<String, dynamic>;
                    final nom =
                        (data['nom'] ?? '').toLowerCase();
                    final dosage =
                        (data['dosage'] ?? '').toLowerCase();
                    return nom.contains(
                            _searchQuery.toLowerCase()) ||
                        dosage.contains(
                            _searchQuery.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/medic.png', width: 200),
                        // Icon(Icons.medication_outlined,
                        //     size: 80, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        const Text('Aucun rappel médicament',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B2B27))),
                        const SizedBox(height: 6),
                        Text(
                            'Appuyez sur + pour en ajouter',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    return _RappelMedTile(
                      data: data,
                      docId: docId,
                      uid: uid,
                      isSelected: _selected.contains(docId),
                      selectionMode: _selectionMode,
                      onLongPress: () => setState(() {
                        _selectionMode = true;
                        _selected.add(docId);
                      }),
                      onSelect: (v) => setState(() {
                        if (v) {
                          _selected.add(docId);
                        } else {
                          _selected.remove(docId);
                          if (_selected.isEmpty)
                            _selectionMode = false;
                        }
                      }),
                      onDelete: () => _supprimerUn(docId, data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_meds',
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        onPressed: () => _showChoixSource(context),
      ),
    );
  }

  Future<void> _supprimerUn(
      String docId, Map<String, dynamic> data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le rappel'),
        content: Text(
            'Voulez-vous supprimer le rappel pour "${data['nom'] ?? ''}" ?'),
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
    final List ids = data['notificationIds'] as List? ?? [];
    for (var id in ids) {
      await NotificationService().annulerRappel(id as int);
    }
    await FirebaseFirestore.instance
        .collection('Rappels')
        .doc(uid)
        .collection('Medicaments')
        .doc(docId)
        .delete();
  }

  Future<void> _supprimerSelection() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la sélection'),
        content: Text(
            'Supprimer ${_selected.length} rappel(s) ?'),
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
    for (final docId in _selected) {
      final snap = await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(uid)
          .collection('Medicaments')
          .doc(docId)
          .get();
      final data = snap.data() ?? {};
      final List ids = data['notificationIds'] as List? ?? [];
      for (var id in ids) {
        await NotificationService().annulerRappel(id as int);
      }
      await snap.reference.delete();
    }
    setState(() {
      _selected.clear();
      _selectionMode = false;
    });
  }

  void _showChoixSource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ajouter un rappel',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Choisissez la source du médicament',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 20),
            _SourceTile(
              icon: Icons.medical_services_outlined,
              color: primary,
              title: 'Depuis une consultation',
              subtitle:
                  'Médicaments prescrits par votre médecin',
              onTap: () {
                Navigator.pop(context);
                _showMedicamentsConsultation(context);
              },
            ),
            const SizedBox(height: 10),
            _SourceTile(
              icon: Icons.healing_outlined,
              color: Colors.orange,
              title: 'Médicament chronique',
              subtitle:
                  'Traitements de fond depuis votre dossier',
              onTap: () {
                Navigator.pop(context);
                _showMedicamentsChroniques(context);
              },
            ),
            const SizedBox(height: 10),
            _SourceTile(
              icon: Icons.add_circle_outline,
              color: Colors.purple,
              title: 'Autre médicament',
              subtitle: 'Saisir manuellement',
              onTap: () {
                Navigator.pop(context);
                _showFormulaireRappel(context,
                    medData: null, source: 'autre');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMedicamentsConsultation(BuildContext context) async {
    final consultSnap = await FirebaseFirestore.instance
        .collection('Dossier_Medical')
        .doc(uid)
        .collection('Consultations')
        .get();

    List<Map<String, dynamic>> tousMeds = [];
    for (var consult in consultSnap.docs) {
      final medsSnap =
          await consult.reference.collection('Medicaments').get();
      for (var med in medsSnap.docs) {
        final data = med.data();
        if ((data['nom'] ?? '').isNotEmpty) {
          tousMeds.add({
            ...data,
            'sourceConsultDate': consult.data()['date'] ?? '',
          });
        }
      }
    }

    if (!mounted) return;
    if (tousMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Aucun médicament dans vos consultations')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              const Text('Choisir un médicament',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: tousMeds.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final med = tousMeds[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            primary.withOpacity(0.12),
                        child: const Icon(
                            Icons.medication_outlined,
                            color: primary,
                            size: 18),
                      ),
                      title: Text(med['nom'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${med['dosage'] ?? ''} • ${med['sourceConsultDate']}',
                          style: const TextStyle(
                              fontSize: 12)),
                      trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        _showFormulaireRappel(context,
                            medData: med,
                            source: 'consultation',
                            sourceDate: med[
                                    'sourceConsultDate'] ??
                                '');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicamentsChroniques(BuildContext context) async {
    final dossierSnap = await FirebaseFirestore.instance
        .collection('Dossier_Medical')
        .doc(uid)
        .get();

    final data = dossierSnap.data() ?? {};
    final List maladies = data['maladies'] as List? ?? [];
    List<Map<String, dynamic>> medsChr = [];
    for (var maladie in maladies) {
      final List meds =
          maladie['medicaments'] as List? ?? [];
      for (var med in meds) {
        medsChr.add({
          ...Map<String, dynamic>.from(med),
          'frequence': med['frequence']?.toString() ?? '1/1',
          'sourceMaladie': maladie['nomMaladie'] ?? '',
        });
      }
    }

    if (!mounted) return;
    if (medsChr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Aucun médicament chronique dans votre dossier')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              const Text('Médicaments chroniques',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: medsChr.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final med = medsChr[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.orange.withOpacity(0.12),
                        child: const Icon(
                            Icons.healing_outlined,
                            color: Colors.orange,
                            size: 18),
                      ),
                      title: Text(med['nom'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Pour : ${med['sourceMaladie']}',
                          style: const TextStyle(
                              fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        _showFormulaireRappel(context,
                            medData: med,
                            source: 'chronique',
                            sourceMaladie:
                                med['sourceMaladie'] ?? '');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFormulaireRappel(
    BuildContext context, {
    Map<String, dynamic>? medData,
    String source = 'autre',
    String sourceMaladie = '',
    String sourceDate = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormulaireRappelMed(
        medData: medData,
        uid: uid,
        source: source,
        sourceMaladie: sourceMaladie,
        sourceDate: sourceDate,
      ),
    );
  }
}

// ── Tile médicament ───────────────────────────────────────────────────────────
class _RappelMedTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelect;
  final VoidCallback onDelete;

  const _RappelMedTile({
    required this.data,
    required this.docId,
    required this.uid,
    required this.isSelected,
    required this.selectionMode,
    required this.onLongPress,
    required this.onSelect,
    required this.onDelete,
  });

  Color get _sourceColor {
    switch (data['source']?.toString() ?? '') {
      case 'chronique':
        return Colors.orange;
      case 'consultation':
        return const Color(0xFF1BC2AB);
      default:
        return Colors.purple;
    }
  }

  IconData get _sourceIcon {
    switch (data['source']?.toString() ?? '') {
      case 'chronique':
        return Icons.healing_outlined;
      case 'consultation':
        return Icons.medical_services_outlined;
      default:
        return Icons.add_circle_outline;
    }
  }

  String get _sourceLabel {
    switch (data['source']?.toString() ?? '') {
      case 'chronique':
        return 'Chronique';
      case 'consultation':
        return 'Consultation';
      default:
        return 'Autre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nom =
        data['nom']?.toString() ?? 'Médicament';
    final String dosage =
        data['dosage']?.toString() ?? '';
    final String frequence =
        data['frequence']?.toString() ?? '';
    final String dateFin =
        data['dateFin']?.toString() ?? '';
    final bool actif = data['actif'] as bool? ?? true;
    final bool estAlarme =
        data['estAlarme'] as bool? ?? false;
    final List heures = data['heures'] as List? ?? [];
    final color = _sourceColor;
    const Color primary = Color(0xFF1BC2AB);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () {
        if (selectionMode) {
          onSelect(!isSelected);
          return;
        }
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20))),
          builder: (_) => _ModifierRappelMed(
              docId: docId, uid: uid, data: data),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? primary.withOpacity(0.08)
            : Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox ou avatar
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (v) => onSelect(v ?? false),
                  activeColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(
                    estAlarme ? Icons.alarm : _sourceIcon,
                    color: color,
                    size: 20,
                  ),
                ),
              ),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + switch
                  Row(children: [
                    Expanded(
                      child: Text(nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1B2B27))),
                    ),
                    if (!selectionMode)
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: actif,
                          activeColor: color,
                          onChanged: (v) async {
                            await FirebaseFirestore.instance
                                .collection('Rappels')
                                .doc(uid)
                                .collection('Medicaments')
                                .doc(docId)
                                .update({'actif': v});
                          },
                        ),
                      ),
                  ]),

                  if (dosage.isNotEmpty)
                    Text(dosage,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500])),
                  const SizedBox(height: 6),

                  // Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Badge(
                          label: _sourceLabel,
                          icon: _sourceIcon,
                          color: color),
                      _Badge(
                        label: estAlarme
                            ? 'Alarme'
                            : 'Notification',
                        icon: estAlarme
                            ? Icons.alarm
                            : Icons.notifications_outlined,
                        color: estAlarme
                            ? Colors.orange
                            : primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Heures
                  if (heures.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: heures.map<Widget>((h) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    color.withOpacity(0.3)),
                          ),
                          child: Text(h?.toString() ?? '',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        );
                      }).toList(),
                    ),

                  // Fréquence + fin
                  if (frequence.isNotEmpty ||
                      dateFin.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        [
                          if (frequence.isNotEmpty)
                            'Fréq. : $frequence',
                          if (dateFin.isNotEmpty)
                            'Fin : ${_fmtDate(dateFin)}',
                        ].join('  •  '),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400]),
                      ),
                    ),

                  // Hint modifier
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Appuyer pour modifier',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[350])),
                  ),
                ],
              ),
            ),

            // Bouton supprimer
            if (!selectionMode)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FORMULAIRE RAPPEL MÉDICAMENT
// ══════════════════════════════════════════════════════════════════════════════
class _FormulaireRappelMed extends StatefulWidget {
  final Map<String, dynamic>? medData;
  final String uid;
  final String source;
  final String sourceMaladie;
  final String sourceDate;

  const _FormulaireRappelMed({
    this.medData,
    required this.uid,
    this.source = 'autre',
    this.sourceMaladie = '',
    this.sourceDate = '',
  });

  @override
  State<_FormulaireRappelMed> createState() =>
      _FormulaireRappelMedState();
}

class _FormulaireRappelMedState
    extends State<_FormulaireRappelMed> {
  static const Color primary = Color(0xFF1BC2AB);
  final _nomCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController(text: '1/1');
  final _dureeCtrl = TextEditingController();
  List<String> _heures = [];
  bool _isSaving = false;
  bool _estAlarme = false;

  @override
  void initState() {
    super.initState();
    if (widget.medData != null) {
      _nomCtrl.text = widget.medData!['nom'] ?? '';
      _dosageCtrl.text = widget.medData!['dosage'] ?? '';
      _freqCtrl.text =
          widget.medData!['frequence']?.toString() ?? '1/1';
    }
    _updateHeures();
  }

  void _updateHeures() {
    int n = _parseFreq(_freqCtrl.text);
    setState(() {
      while (_heures.length < n) _heures.add('');
      while (_heures.length > n) _heures.removeLast();
    });
  }

  int _parseFreq(String f) {
    if (f.contains('/'))
      return int.tryParse(f.split('/')[0].trim()) ?? 1;
    return int.tryParse(f.trim()) ?? 1;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _dureeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Le nom du médicament est obligatoire')));
      return;
    }
    if (_heures.any((h) => h.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez remplir toutes les heures')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final int dureeJours =
          int.tryParse(_dureeCtrl.text.trim()) ?? 0;
      List<int> notifIds = [];

      for (var heure in _heures) {
        final parts = heure.split(':');
        final tod = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]));
        final int id = NotificationService().genererID();
        await NotificationService().planifierRappelQuotidien(
          id: id,
          titre: _estAlarme
              ? '⏰ ${_nomCtrl.text}'
              : '💊 ${_nomCtrl.text}',
          corps: _dosageCtrl.text.isNotEmpty
              ? 'Dose : ${_dosageCtrl.text}'
              : 'Heure de prendre votre médicament',
          heure: tod,
          estAlarme: _estAlarme,
          dureeJours: dureeJours,
        );
        notifIds.add(id);
      }

      final dateFin = dureeJours > 0
          ? DateTime.now()
              .add(Duration(days: dureeJours))
              .toIso8601String()
          : null;

      await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(widget.uid)
          .collection('Medicaments')
          .add({
        'nom': _nomCtrl.text.trim(),
        'dosage': _dosageCtrl.text.trim(),
        'frequence': _freqCtrl.text.trim(),
        'duree': _dureeCtrl.text.trim(),
        'heures': _heures,
        'estAlarme': _estAlarme,
        'dateFin': dateFin,
        'actif': true,
        'source': widget.source,
        'sourceMaladie': widget.sourceMaladie,
        'sourceDate': widget.sourceDate,
        'notificationIds': notifIds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _estAlarme ? 'Alarme activée !' : 'Rappel activé !'),
        backgroundColor: primary,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Configurer le rappel',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            _Field(
                ctrl: _nomCtrl,
                label: 'Nom du médicament',
                icon: Icons.medication),
            _Field(
                ctrl: _dosageCtrl,
                label: 'Dosage (ex: 500mg)',
                icon: Icons.science_outlined),
            _Field(
              ctrl: _freqCtrl,
              label: 'Fréquence (ex: 2/1 = 2×/jour)',
              icon: Icons.repeat,
              onChanged: (_) => _updateHeures(),
            ),
            _Field(
                ctrl: _dureeCtrl,
                label: 'Durée (jours, 0 = illimitée)',
                icon: Icons.timer_outlined,
                isNum: true),

            // Heures de prise
            if (_heures.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Heures de prise',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1BC2AB))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_heures.length, (i) {
                  return GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme:
                                const ColorScheme.light(
                                    primary:
                                        Color(0xFF1BC2AB)),
                          ),
                          child: child!,
                        ),
                      );
                      if (t != null) {
                        setState(() {
                          _heures[i] =
                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _heures[i].isEmpty
                            ? Colors.grey[100]
                            : const Color(0xFF1BC2AB)
                                .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: _heures[i].isEmpty
                                ? Colors.grey
                                : const Color(0xFF1BC2AB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time,
                              size: 16,
                              color: _heures[i].isEmpty
                                  ? Colors.grey
                                  : const Color(0xFF1BC2AB)),
                          const SizedBox(width: 6),
                          Text(
                            _heures[i].isEmpty
                                ? 'Prise ${i + 1}'
                                : _heures[i],
                            style: TextStyle(
                              color: _heures[i].isEmpty
                                  ? Colors.grey
                                  : const Color(0xFF1BC2AB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],

            // Toggle alarme/notification
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _estAlarme
                    ? Colors.orange.withOpacity(0.08)
                    : const Color(0xFF1BC2AB).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _estAlarme
                      ? Colors.orange.withOpacity(0.4)
                      : const Color(0xFF1BC2AB).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _estAlarme
                        ? Icons.alarm
                        : Icons.notifications_outlined,
                    color: _estAlarme
                        ? Colors.orange
                        : const Color(0xFF1BC2AB),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estAlarme
                              ? 'Mode Alarme'
                              : 'Mode Notification',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _estAlarme
                                ? Colors.orange
                                : const Color(0xFF1BC2AB),
                          ),
                        ),
                        Text(
                          _estAlarme
                              ? "Sonne fort, reste à l'écran"
                              : 'Notification discrète',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _estAlarme,
                    activeColor: Colors.orange,
                    inactiveThumbColor:
                        const Color(0xFF1BC2AB),
                    inactiveTrackColor:
                        const Color(0xFF1BC2AB)
                            .withOpacity(0.3),
                    onChanged: (v) =>
                        setState(() => _estAlarme = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _estAlarme
                      ? Colors.orange
                      : const Color(0xFF1BC2AB),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _sauvegarder,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : Text(
                        _estAlarme
                            ? "Activer l'alarme"
                            : 'Activer le rappel',
                        style: const TextStyle(
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

// ══════════════════════════════════════════════════════════════════════════════
// MODIFIER RAPPEL MÉDICAMENT
// ══════════════════════════════════════════════════════════════════════════════
class _ModifierRappelMed extends StatefulWidget {
  final String docId;
  final String uid;
  final Map<String, dynamic> data;

  const _ModifierRappelMed(
      {required this.docId,
      required this.uid,
      required this.data});

  @override
  State<_ModifierRappelMed> createState() =>
      _ModifierRappelMedState();
}

class _ModifierRappelMedState
    extends State<_ModifierRappelMed> {
  static const Color primary = Color(0xFF1BC2AB);
  late TextEditingController _nomCtrl;
  late TextEditingController _dosageCtrl;
  late TextEditingController _freqCtrl;
  late TextEditingController _dureeCtrl;
  late List<String> _heures;
  late bool _estAlarme;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(
        text: widget.data['nom']?.toString() ?? '');
    _dosageCtrl = TextEditingController(
        text: widget.data['dosage']?.toString() ?? '');
    _freqCtrl = TextEditingController(
        text:
            widget.data['frequence']?.toString() ?? '1/1');
    _dureeCtrl = TextEditingController(
        text: widget.data['duree']?.toString() ?? '');
    _heures = List<String>.from(
        (widget.data['heures'] as List? ?? [])
            .map((e) => e.toString()));
    _estAlarme = widget.data['estAlarme'] as bool? ?? false;
    _syncHeures();
  }

  void _syncHeures() {
    int n = _parseFreq(_freqCtrl.text);
    while (_heures.length < n) _heures.add('');
    while (_heures.length > n) _heures.removeLast();
  }

  int _parseFreq(String f) {
    if (f.contains('/'))
      return int.tryParse(f.split('/')[0].trim()) ?? 1;
    return int.tryParse(f.trim()) ?? 1;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _dureeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (_nomCtrl.text.trim().isEmpty) return;
    if (_heures.any((h) => h.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Veuillez remplir toutes les heures')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final List oldIds =
          widget.data['notificationIds'] as List? ?? [];
      for (var id in oldIds) {
        await NotificationService().annulerRappel(id as int);
      }

      final int dureeJours =
          int.tryParse(_dureeCtrl.text.trim()) ?? 0;
      List<int> notifIds = [];
      for (var heure in _heures) {
        final parts = heure.split(':');
        final tod = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]));
        final int id = NotificationService().genererID();
        await NotificationService().planifierRappelQuotidien(
          id: id,
          titre: _estAlarme
              ? '⏰ ${_nomCtrl.text}'
              : '💊 ${_nomCtrl.text}',
          corps: _dosageCtrl.text.isNotEmpty
              ? 'Dose : ${_dosageCtrl.text}'
              : 'Heure de prendre votre médicament',
          heure: tod,
          estAlarme: _estAlarme,
          dureeJours: dureeJours,
        );
        notifIds.add(id);
      }

      final dateFin = dureeJours > 0
          ? DateTime.now()
              .add(Duration(days: dureeJours))
              .toIso8601String()
          : null;

      await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(widget.uid)
          .collection('Medicaments')
          .doc(widget.docId)
          .update({
        'nom': _nomCtrl.text.trim(),
        'dosage': _dosageCtrl.text.trim(),
        'frequence': _freqCtrl.text.trim(),
        'duree': _dureeCtrl.text.trim(),
        'heures': _heures,
        'estAlarme': _estAlarme,
        'dateFin': dateFin,
        'notificationIds': notifIds,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Rappel modifié !'),
          backgroundColor: primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.edit_outlined,
                  color: primary, size: 20),
              const SizedBox(width: 8),
              const Text('Modifier le rappel',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
            const SizedBox(height: 16),
            _Field(
                ctrl: _nomCtrl,
                label: 'Nom',
                icon: Icons.medication),
            _Field(
                ctrl: _dosageCtrl,
                label: 'Dosage',
                icon: Icons.science_outlined),
            _Field(
              ctrl: _freqCtrl,
              label: 'Fréquence (ex: 2/1)',
              icon: Icons.repeat,
              onChanged: (_) =>
                  setState(() => _syncHeures()),
            ),
            _Field(
                ctrl: _dureeCtrl,
                label: 'Durée (jours, 0 = illimitée)',
                icon: Icons.timer_outlined,
                isNum: true),

            if (_heures.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Heures de prise',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_heures.length, (i) {
                  return GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme:
                                const ColorScheme.light(
                                    primary: primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (t != null) {
                        setState(() {
                          _heures[i] =
                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _heures[i].isEmpty
                            ? Colors.grey[100]
                            : primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: _heures[i].isEmpty
                                ? Colors.grey
                                : primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time,
                              size: 16,
                              color: _heures[i].isEmpty
                                  ? Colors.grey
                                  : primary),
                          const SizedBox(width: 6),
                          Text(
                            _heures[i].isEmpty
                                ? 'Prise ${i + 1}'
                                : _heures[i],
                            style: TextStyle(
                              color: _heures[i].isEmpty
                                  ? Colors.grey
                                  : primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _estAlarme
                    ? Colors.orange.withOpacity(0.08)
                    : primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _estAlarme
                      ? Colors.orange.withOpacity(0.4)
                      : primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _estAlarme
                        ? Icons.alarm
                        : Icons.notifications_outlined,
                    color: _estAlarme
                        ? Colors.orange
                        : primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estAlarme
                              ? 'Mode Alarme'
                              : 'Mode Notification',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _estAlarme
                                ? Colors.orange
                                : primary,
                          ),
                        ),
                        Text(
                          _estAlarme
                              ? "Sonne fort, reste à l'écran"
                              : 'Notification discrète',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _estAlarme,
                    activeColor: Colors.orange,
                    inactiveThumbColor: primary,
                    inactiveTrackColor:
                        primary.withOpacity(0.3),
                    onChanged: (v) =>
                        setState(() => _estAlarme = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _estAlarme
                      ? Colors.orange
                      : primary,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _sauvegarder,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Text(
                        'Enregistrer les modifications',
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

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — RENDEZ-VOUS
// ══════════════════════════════════════════════════════════════════════════════
class _RendezVousRappelsTab extends StatefulWidget {
  const _RendezVousRappelsTab();

  @override
  State<_RendezVousRappelsTab> createState() =>
      _RendezVousRappelsTabState();
}

class _RendezVousRappelsTabState
    extends State<_RendezVousRappelsTab> {
  static const Color primary = Color(0xFF1BC2AB);
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  bool _showPasses = false;
  final Set<String> _selected = {};
  bool _selectionMode = false;
  String _searchQuery = '';

  Stream<QuerySnapshot> get _rdvStream => FirebaseFirestore
      .instance
      .collection('Rappels')
      .doc(uid)
      .collection('RendezVous')
      .orderBy('dateHeure')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Toggle À venir / Passés
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          //   child: Container(
          //     padding: const EdgeInsets.all(4),
          //     decoration: BoxDecoration(
          //       color: Colors.grey[100],
          //       borderRadius: BorderRadius.circular(30),
          //     ),
          //     child: Row(
          //       children: [
          //         _ToggleBtn(
          //           label: 'À venir',
          //           active: !_showPasses,
          //           onTap: () =>
          //               setState(() => _showPasses = false),
          //         ),
          //         _ToggleBtn(
          //           label: 'Passé(s)',
          //           active: _showPasses,
          //           onTap: () =>
          //               setState(() => _showPasses = true),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // ✅ AJOUTER — barre de recherche RDV
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un rendez-vous...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
              ),
            ),
          ),
          

          // Barre sélection
          if (_selectionMode)
            Container(
              // ignore: deprecated_member_use
              color: primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text('${_selected.length} sélectionné(s)',
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _supprimerSelection,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label: const Text('Supprimer',
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectionMode = false;
                      _selected.clear();
                    }),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _rdvStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final allDocs = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                final docs = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data['dateHeure'] as Timestamp?;
                final dt = ts?.toDate();
                if (dt == null) return false;

                // Filtre passé/à venir
                final dateOk = _showPasses
                    ? dt.isBefore(now)
                    : dt.isAfter(now);
                if (!dateOk) return false;

                // ✅ Filtre recherche texte
                if (_searchQuery.isEmpty) return true;
                final q       = _searchQuery.toLowerCase();
                final medecin = (data['medecin'] ?? '').toLowerCase();
                final motif   = (data['motif']   ?? '').toLowerCase();
                final lieu    = (data['lieu']    ?? '').toLowerCase();
                // ✅ Recherche aussi dans la date formatée
                final dateStr =
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

                return medecin.contains(q) ||
                      motif.contains(q)   ||
                      lieu.contains(q)    ||
                      dateStr.contains(q);
              }).toList();

                if (docs.isEmpty) {
                  return _EmptyRdv(
                      showPasses: _showPasses);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16),
                  itemBuilder: (context, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    return _RappelRdvTile(
                      data: data,
                      docId: docId,
                      uid: uid,
                      isSelected:
                          _selected.contains(docId),
                      selectionMode: _selectionMode,
                      onLongPress: () => setState(() {
                        _selectionMode = true;
                        _selected.add(docId);
                      }),
                      onSelect: (v) => setState(() {
                        if (v) {
                          _selected.add(docId);
                        } else {
                          _selected.remove(docId);
                          if (_selected.isEmpty)
                            _selectionMode = false;
                        }
                      }),
                      onDelete: () =>
                          _supprimerUn(docId, data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_rdv',
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Rendez-vous',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        onPressed: () => _showFormulaireRdv(context),
      ),
    );
  }

  void _showFormulaireRdv(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormulaireRdv(uid: uid),
    );
  }

  Future<void> _supprimerUn(
      String docId, Map<String, dynamic> data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le rendez-vous'),
        content: const Text(
            'Voulez-vous supprimer ce rendez-vous ?'),
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
    final List ids =
        data['notificationIds'] as List? ?? [];
    for (var id in ids) {
      await NotificationService().annulerRappel(id as int);
    }
    await FirebaseFirestore.instance
        .collection('Rappels')
        .doc(uid)
        .collection('RendezVous')
        .doc(docId)
        .delete();
  }

  Future<void> _supprimerSelection() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la sélection'),
        content: Text(
            'Supprimer ${_selected.length} rendez-vous ?'),
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
    for (final docId in _selected) {
      final snap = await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(uid)
          .collection('RendezVous')
          .doc(docId)
          .get();
      final data = snap.data() ?? {};
      final List ids =
          data['notificationIds'] as List? ?? [];
      for (var id in ids) {
        await NotificationService().annulerRappel(id as int);
      }
      await snap.reference.delete();
    }
    setState(() {
      _selected.clear();
      _selectionMode = false;
    });
  }
}

// ── Tile RDV ──────────────────────────────────────────────────────────────────
class _RappelRdvTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelect;
  final VoidCallback onDelete;

  const _RappelRdvTile({
    required this.data,
    required this.docId,
    required this.uid,
    required this.isSelected,
    required this.selectionMode,
    required this.onLongPress,
    required this.onSelect,
    required this.onDelete,
  });

  String _moisCourt(int m) {
    const mois = [
      'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN',
      'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC'
    ];
    return mois[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp? ts = data['dateHeure'] as Timestamp?;
    final DateTime? dt = ts?.toDate();
    final bool isPast =
        dt != null && dt.isBefore(DateTime.now());
    final String medecin =
        data['medecin']?.toString() ?? '';
    final String motif = data['motif']?.toString() ?? '';
    final String lieu = data['lieu']?.toString() ?? '';
    const Color primary = Color(0xFF1BC2AB);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () {
        if (selectionMode) {
          onSelect(!isSelected);
          return;
        }
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20))),
          builder: (_) => _ModifierRappelRdv(
              docId: docId, uid: uid, data: data),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? primary.withOpacity(0.08)
            : Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Checkbox ou bloc date
            if (selectionMode)
              Padding(
                padding:
                    const EdgeInsets.only(right: 12),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (v) =>
                      onSelect(v ?? false),
                  activeColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(4)),
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.only(right: 14),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey[100]
                        : primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        dt != null
                            ? dt.day
                                .toString()
                                .padLeft(2, '0')
                            : '--',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPast
                                ? Colors.grey
                                : primary),
                      ),
                      Text(
                        dt != null
                            ? _moisCourt(dt.month)
                            : '',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isPast
                                ? Colors.grey
                                : primary),
                      ),
                    ],
                  ),
                ),
              ),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    medecin.isNotEmpty
                        ? medecin
                        : 'Rendez-vous médical',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1B2B27)),
                  ),
                  if (motif.isNotEmpty)
                    Text(motif,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500])),
                  if (dt != null)
                    Row(children: [
                      Icon(Icons.access_time,
                          size: 12,
                          color: isPast
                              ? Colors.grey
                              : primary),
                      const SizedBox(width: 4),
                      Text(
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPast
                                ? Colors.grey
                                : primary),
                      ),
                      if (isPast) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          child: const Text('Passé',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey)),
                        ),
                      ],
                    ]),
                  if (lieu.isNotEmpty)
                    Row(children: [
                      const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(lieu,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400]),
                            overflow:
                                TextOverflow.ellipsis),
                      ),
                    ]),
                  const SizedBox(height: 4),
                  Text('Appuyer pour modifier',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400])),
                ],
              ),
            ),

            if (!selectionMode)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty RDV ─────────────────────────────────────────────────────────────────
class _EmptyRdv extends StatelessWidget {
  final bool showPasses;
  const _EmptyRdv({required this.showPasses});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Remplace par Image.asset si tu as une image :
            Image.asset('assets/images/calendrier.png', width: 200),
            // Icon(Icons.calendar_month_outlined,
            //     size: 90, color: Colors.grey[200]),
            const SizedBox(height: 20),
            Text(
              showPasses
                  ? 'Aucun rendez-vous réalisé'
                  : 'Aucun rendez-vous à venir',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2B27)),
            ),
            const SizedBox(height: 8),
            Text(
              showPasses
                  ? 'Vos anciens rendez-vous apparaîtront ici'
                  : 'Planifiez votre prochain rendez-vous',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FORMULAIRE RENDEZ-VOUS
// ══════════════════════════════════════════════════════════════════════════════
class _FormulaireRdv extends StatefulWidget {
  final String uid;
  const _FormulaireRdv({required this.uid});

  @override
  State<_FormulaireRdv> createState() =>
      _FormulaireRdvState();
}

class _FormulaireRdvState extends State<_FormulaireRdv> {
  static const Color primary = Color(0xFF1BC2AB);
  final _medecinCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  DateTime? _dateRdv;
  TimeOfDay? _heureRdv;
  bool _isSaving = false;

  @override
  void dispose() {
    _medecinCtrl.dispose();
    _motifCtrl.dispose();
    _lieuCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (_dateRdv == null || _heureRdv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Veuillez choisir la date et l'heure")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dateHeure = DateTime(
        _dateRdv!.year,
        _dateRdv!.month,
        _dateRdv!.day,
        _heureRdv!.hour,
        _heureRdv!.minute,
      );
      final int id = NotificationService().genererID();
      await NotificationService().planifierRappelUnique(
        id: id,
        titre: '📅 Rendez-vous médical',
        corps: _medecinCtrl.text.isNotEmpty
            ? 'Chez ${_medecinCtrl.text}${_motifCtrl.text.isNotEmpty ? ' — ${_motifCtrl.text}' : ''}'
            : 'Vous avez un rendez-vous',
        dateHeure: dateHeure,
      );
      await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(widget.uid)
          .collection('RendezVous')
          .add({
        'medecin': _medecinCtrl.text.trim(),
        'motif': _motifCtrl.text.trim(),
        'lieu': _lieuCtrl.text.trim(),
        'dateHeure': Timestamp.fromDate(dateHeure),
        'notificationIds': [id],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rendez-vous enregistré !'),
              backgroundColor: primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nouveau rendez-vous',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 16),
            _Field(
                ctrl: _medecinCtrl,
                label: 'Médecin (optionnel)',
                icon: Icons.person_outline),
            _Field(
                ctrl: _motifCtrl,
                label: 'Motif (optionnel)',
                icon: Icons.notes),
            _Field(
                ctrl: _lieuCtrl,
                label: 'Lieu / Adresse',
                icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now()
                      .add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 2)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme:
                          const ColorScheme.light(
                              primary: primary),
                    ),
                    child: child!,
                  ),
                );
                if (d != null)
                  setState(() => _dateRdv = d);
              },
              child: _DateTimeSelector(
                icon: Icons.calendar_today,
                label: _dateRdv == null
                    ? 'Choisir la date *'
                    : '${_dateRdv!.day.toString().padLeft(2, '0')}/${_dateRdv!.month.toString().padLeft(2, '0')}/${_dateRdv!.year}',
                isSet: _dateRdv != null,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme:
                          const ColorScheme.light(
                              primary: primary),
                    ),
                    child: child!,
                  ),
                );
                if (t != null)
                  setState(() => _heureRdv = t);
              },
              child: _DateTimeSelector(
                icon: Icons.access_time,
                label: _heureRdv == null
                    ? "Choisir l'heure *"
                    : '${_heureRdv!.hour.toString().padLeft(2, '0')}:${_heureRdv!.minute.toString().padLeft(2, '0')}',
                isSet: _heureRdv != null,
              ),
            ),
            const SizedBox(height: 24),
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
                onPressed:
                    _isSaving ? null : _sauvegarder,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Text(
                        'Enregistrer le rendez-vous',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODIFIER RENDEZ-VOUS
// ══════════════════════════════════════════════════════════════════════════════
class _ModifierRappelRdv extends StatefulWidget {
  final String docId;
  final String uid;
  final Map<String, dynamic> data;

  const _ModifierRappelRdv(
      {required this.docId,
      required this.uid,
      required this.data});

  @override
  State<_ModifierRappelRdv> createState() =>
      _ModifierRappelRdvState();
}

class _ModifierRappelRdvState
    extends State<_ModifierRappelRdv> {
  static const Color primary = Color(0xFF1BC2AB);
  late TextEditingController _medecinCtrl;
  late TextEditingController _motifCtrl;
  late TextEditingController _lieuCtrl;
  DateTime? _dateRdv;
  TimeOfDay? _heureRdv;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _medecinCtrl = TextEditingController(
        text: widget.data['medecin']?.toString() ?? '');
    _motifCtrl = TextEditingController(
        text: widget.data['motif']?.toString() ?? '');
    _lieuCtrl = TextEditingController(
        text: widget.data['lieu']?.toString() ?? '');
    final Timestamp? ts =
        widget.data['dateHeure'] as Timestamp?;
    if (ts != null) {
      final dt = ts.toDate();
      _dateRdv = DateTime(dt.year, dt.month, dt.day);
      _heureRdv =
          TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  @override
  void dispose() {
    _medecinCtrl.dispose();
    _motifCtrl.dispose();
    _lieuCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (_dateRdv == null || _heureRdv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Veuillez choisir la date et l'heure")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dateHeure = DateTime(
        _dateRdv!.year,
        _dateRdv!.month,
        _dateRdv!.day,
        _heureRdv!.hour,
        _heureRdv!.minute,
      );
      final List oldIds =
          widget.data['notificationIds'] as List? ?? [];
      for (var id in oldIds) {
        await NotificationService().annulerRappel(id as int);
      }
      final int id = NotificationService().genererID();
      await NotificationService().planifierRappelUnique(
        id: id,
        titre: '📅 Rendez-vous médical',
        corps: _medecinCtrl.text.isNotEmpty
            ? 'Chez ${_medecinCtrl.text}'
            : 'Vous avez un rendez-vous',
        dateHeure: dateHeure,
      );
      await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(widget.uid)
          .collection('RendezVous')
          .doc(widget.docId)
          .update({
        'medecin': _medecinCtrl.text.trim(),
        'motif': _motifCtrl.text.trim(),
        'lieu': _lieuCtrl.text.trim(),
        'dateHeure': Timestamp.fromDate(dateHeure),
        'notificationIds': [id],
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rendez-vous modifié !'),
              backgroundColor: primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.edit_outlined,
                  color: primary, size: 20),
              const SizedBox(width: 8),
              const Text('Modifier le rendez-vous',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
            const SizedBox(height: 16),
            _Field(
                ctrl: _medecinCtrl,
                label: 'Médecin (optionnel)',
                icon: Icons.person_outline),
            _Field(
                ctrl: _motifCtrl,
                label: 'Motif (optionnel)',
                icon: Icons.notes),
            _Field(
                ctrl: _lieuCtrl,
                label: 'Lieu / Adresse',
                icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dateRdv ??
                      DateTime.now()
                          .add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365 * 2)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme:
                          const ColorScheme.light(
                              primary: primary),
                    ),
                    child: child!,
                  ),
                );
                if (d != null)
                  setState(() => _dateRdv = d);
              },
              child: _DateTimeSelector(
                icon: Icons.calendar_today,
                label: _dateRdv == null
                    ? 'Choisir la date *'
                    : '${_dateRdv!.day.toString().padLeft(2, '0')}/${_dateRdv!.month.toString().padLeft(2, '0')}/${_dateRdv!.year}',
                isSet: _dateRdv != null,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime:
                      _heureRdv ?? TimeOfDay.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme:
                          const ColorScheme.light(
                              primary: primary),
                    ),
                    child: child!,
                  ),
                );
                if (t != null)
                  setState(() => _heureRdv = t);
              },
              child: _DateTimeSelector(
                icon: Icons.access_time,
                label: _heureRdv == null
                    ? "Choisir l'heure *"
                    : '${_heureRdv!.hour.toString().padLeft(2, '0')}:${_heureRdv!.minute.toString().padLeft(2, '0')}',
                isSet: _heureRdv != null,
              ),
            ),
            const SizedBox(height: 24),
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
                onPressed:
                    _isSaving ? null : _sauvegarder,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS HELPERS COMMUNS
// ══════════════════════════════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge(
      {required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}



class _SourceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withOpacity(0.25)),
          color: color.withOpacity(0.04),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isNum;
  final ValueChanged<String>? onChanged;

  const _Field({
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
        keyboardType: isNum
            ? TextInputType.number
            : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon,
              color: const Color(0xFF1BC2AB)),
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

class _DateTimeSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSet;

  const _DateTimeSelector({
    required this.icon,
    required this.label,
    required this.isSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSet
                ? const Color(0xFF1BC2AB)
                : Colors.grey[400]!),
        color: isSet
            ? const Color(0xFF1BC2AB).withOpacity(0.05)
            : Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isSet
                  ? const Color(0xFF1BC2AB)
                  : Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSet
                  ? const Color(0xFF1BC2AB)
                  : Colors.grey,
              fontWeight: isSet
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}