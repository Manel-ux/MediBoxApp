import 'package:carnetdesante/dossier/dossier_screen.dart';
import 'package:carnetdesante/sante/mensurartion_screen.dart';
import 'package:carnetdesante/views/home/add_consultation_stepper.dart';
import 'package:carnetdesante/views/rappels/rappels_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF1BC2AB);
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;
  final Set<String> _medicamentsCochesManuellement = {};

  // ── Données chargées ───────────────────────────────
  String _prenom = '';
  int _nbConsultations = 0;
  int _nbRappels = 0;
  List<Map<String, dynamic>> _rappelsAujourdhui = [];
  List<Map<String, dynamic>> _rdvAvenir = [];
  List<Map<String, dynamic>> _activiteRecente = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      _prenom = user?.displayName?.split(' ').first ?? '';

      final now = DateTime.now();

      // ── Consultations ──────────────────────────────
      final consultSnap = await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(uid)
          .collection('Consultations')
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 8));

      _nbConsultations = consultSnap.docs.length;

      // ── Rappels médicaments du jour ────────────────
      final medsSnap = await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(uid)
          .collection('Medicaments')
          .where('actif', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 8));

      _rappelsAujourdhui = [];
      for (var doc in medsSnap.docs) {
        final data = doc.data();
        final List heures = data['heures'] as List? ?? [];
        for (var h in heures) {
          _rappelsAujourdhui.add({
            'type': 'medicament',
            'nom': data['nom'] ?? '',
            'heure': h.toString(),
            'dosage': data['dosage'] ?? '',
            'source': data['source'] ?? 'autre',
            'docId': doc.id,
          });
        }
      }
      // Trie par heure
      _rappelsAujourdhui.sort((a, b) =>
          a['heure'].compareTo(b['heure']));

      _nbRappels = medsSnap.docs.length;

      // ── RDV à venir ────────────────────────────────
      final rdvSnap = await FirebaseFirestore.instance
          .collection('Rappels')
          .doc(uid)
          .collection('RendezVous')
          .get()
          .timeout(const Duration(seconds: 8));

      _rdvAvenir = rdvSnap.docs
          .map((d) => {
                ...d.data(),
                'docId': d.id,
              })
          .where((d) {
        final ts = d['dateHeure'] as Timestamp?;
        return ts != null && ts.toDate().isAfter(now);
      }).toList();

      // ── Activité récente ───────────────────────────
      _activiteRecente = [];

      // Dernières consultations
      for (var doc in consultSnap.docs.take(3)) {
        final data = doc.data();
        final String prenom =
            data['medecinPrenom']?.toString() ?? '';
        final String nom =
            data['medecinNom']?.toString() ?? '';
        final String medecin = '$prenom $nom'.trim();
        _activiteRecente.add({
          'type': 'consultation',
          'titre': data['motif'] ?? 'Consultation',
          'sous': medecin.isNotEmpty
              ? '${data['date'] ?? ''} • Dr. $medecin'
              : data['date'] ?? '',
          'icon': Icons.calendar_today_outlined,
          'color': primary,
        });
      }

      // Derniers rappels
      for (var doc in medsSnap.docs.take(2)) {
        final data = doc.data();
        final List heures = data['heures'] as List? ?? [];
        _activiteRecente.add({
          'type': 'rappel',
          'titre': 'Rappel ${data['nom'] ?? ''}',
          'sous': heures.isNotEmpty
              ? heures.join(', ')
              : '',
          'icon': Icons.medication_outlined,
          'color': Colors.orange,
        });
      }

      // Derniers RDV
      for (var rdv in _rdvAvenir.take(1)) {
        final ts = rdv['dateHeure'] as Timestamp?;
        final dt = ts?.toDate();
        _activiteRecente.add({
          'type': 'rdv',
          'titre': rdv['medecin']?.isNotEmpty == true
              ? 'RDV avec ${rdv['medecin']}'
              : 'Rendez-vous médical',
          'sous': dt != null
              ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
              : '',
          'icon': Icons.event_outlined,
          'color': Colors.blue,
        });
      }

      // Tronque à 5 éléments
      if (_activiteRecente.length > 5) {
        _activiteRecente = _activiteRecente.sublist(0, 5);
      }
    } catch (e) {
      debugPrint('Erreur chargement home : $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: primary,
              onRefresh: _chargerDonnees,
              child: CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),

                        // ── Aujourd'hui / À venir ───────────
                        _buildAujourdhuiSection(),
                        const SizedBox(height: 24),

                        // ── Actions rapides ─────────────────
                        _buildActionsRapides(),
                        const SizedBox(height: 24),

                        // ── Activité récente ─────────────────
                        _buildActiviteRecente(),
                        const SizedBox(height: 24),

                        // ── Conseil du jour ──────────────────
                        _buildConseilDuJour(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1BC2AB), Color(0xFF0FA896)],
        ),
        borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Salutation ──────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_salutation,',
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _prenom.isEmpty
                              ? 'Mon Carnet'
                              : _prenom,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icône refresh
                  GestureDetector(
                    onTap: _chargerDonnees,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Carte santé globale ──────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Santé globale',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Icon(Icons.trending_up,
                            color: Colors.white, size: 20),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Consultations',
                          value: '$_nbConsultations',
                        ),
                        const SizedBox(width: 20),
                        _StatChip(
                          label: 'Rappels',
                          value: '$_nbRappels',
                        ),
                        const SizedBox(width: 20),
                        _StatChip(
                          label: 'RDV à venir',
                          value: '${_rdvAvenir.length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Aujourd'hui / À venir ─────────────────────────────────────────────────
  Widget _buildAujourdhuiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Switch Aujourd'hui / À venir
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return Row(
                children: [
                  _TabBtn(
                    label: "Aujourd'hui",
                    active: _tabController.index == 0,
                    onTap: () =>
                        _tabController.animateTo(0),
                  ),
                  _TabBtn(
                    label: 'À venir',
                    active: _tabController.index == 1,
                    onTap: () =>
                        _tabController.animateTo(1),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Contenu selon onglet
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            if (_tabController.index == 0) {
              return _buildRappelsAujourdhui();
            } else {
              return _buildRdvAvenir();
            }
          },
        ),
      ],
    );
  }

  Widget _buildRappelsAujourdhui() {
    if (_rappelsAujourdhui.isEmpty) {
      return _EmptyCard(
        icon: Icons.check_circle_outline,
        message: 'Aucun rappel pour aujourd\'hui',
        color: primary,
      );
    }

    return Column(
      children: _rappelsAujourdhui.map((r) {
        // ✅ Cochée uniquement si l'utilisateur a cliqué sur "Marquer"
        final String cleUnique =
            '${r['docId']}_${r['heure']}';
        final bool coche = _medicamentsCochesManuellement
            .contains(cleUnique);
        final Color color = _sourceColor(r['source']);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: coche
                  ? Colors.grey[200]!
                  : color.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ✅ Icône — cochée seulement si marquée manuellement
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: coche
                      ? Colors.grey[100]
                      : color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  coche
                      ? Icons.check_circle
                      : Icons.medication_outlined,
                  color: coche ? Colors.grey : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['nom'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        // ✅ Barré seulement si marqué manuellement
                        color: coche
                            ? Colors.grey
                            : const Color(0xFF1B2B27),
                        decoration: coche
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if ((r['dosage'] ?? '').isNotEmpty)
                      Text(r['dosage'],
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500])),
                  ],
                ),
              ),

              // Heure
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: coche
                      ? Colors.grey[100]
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r['heure'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: coche ? Colors.grey : color,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ✅ Bouton Marquer / Décocher
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (coche) {
                      // ✅ Décoche si déjà marqué
                      _medicamentsCochesManuellement
                          .remove(cleUnique);
                    } else {
                      // ✅ Marque comme pris
                      _medicamentsCochesManuellement
                          .add(cleUnique);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                              '${r['nom']} marqué comme pris ✓'),
                          backgroundColor: primary,
                          duration:
                              const Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                },
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: coche
                        ? Colors.grey[100]
                        : primary,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: coche
                        ? Border.all(
                            color: Colors.grey[300]!)
                        : null,
                  ),
                  child: Text(
                    coche ? 'Annuler' : 'Marquer',
                    style: TextStyle(
                      color: coche
                          ? Colors.grey
                          : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRdvAvenir() {
    if (_rdvAvenir.isEmpty) {
      return _EmptyCard(
        icon: Icons.calendar_today_outlined,
        message: 'Aucun rendez-vous à venir',
        color: Colors.blue,
      );
    }

    return Column(
      children: _rdvAvenir.take(5).map((rdv) {
        final ts = rdv['dateHeure'] as Timestamp?;
        final dt = ts?.toDate();
        final String medecin =
            rdv['medecin']?.toString() ?? '';
        final String motif =
            rdv['motif']?.toString() ?? '';
        final String lieu =
            rdv['lieu']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.blue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bloc date
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      dt != null
                          ? _moisCourt(dt.month)
                          : '',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

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
                        fontSize: 14,
                        color: Color(0xFF1B2B27),
                      ),
                    ),
                    if (motif.isNotEmpty)
                      Text(motif,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500])),
                    if (dt != null)
                      Row(children: [
                        const Icon(Icons.access_time,
                            size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue),
                        ),
                        if (lieu.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.grey),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(lieu,
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.grey[400]),
                                overflow:
                                    TextOverflow.ellipsis),
                          ),
                        ],
                      ]),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Actions rapides ───────────────────────────────────────────────────────
  Widget _buildActionsRapides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2B27),
          ),
        ),
        const SizedBox(height: 1),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _ActionCard(
              icon: Icons.add_circle_outline,
              label: 'Nouvelle consultation',
              color: primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const AddConsultationStepper()),
              ),
            ),
            _ActionCard(
              icon: Icons.medication_outlined,
              label: 'Nouveau rappel',
              color: Colors.orange,
              onTap: () {
                // ✅ Navigue vers l'onglet rappels
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const RappelsScreen()),
                );
              },
            ),
            _ActionCard(
              icon: Icons.monitor_heart_outlined,
              label: 'Mesures de santé',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MensurationsScreen()),
              ),
            ),
            _ActionCard(
              icon: Icons.folder_outlined,
              label: 'Mon dossier',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DossierScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Activité récente ──────────────────────────────────────────────────────
  Widget _buildActiviteRecente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2B27),
          ),
        ),
        const SizedBox(height: 12),
        if (_activiteRecente.isEmpty)
          _EmptyCard(
            icon: Icons.history,
            message: 'Aucune activité récente',
            color: Colors.grey,
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _activiteRecente
                  .asMap()
                  .entries
                  .map((entry) {
                final i = entry.key;
                final act = entry.value;
                final isLast =
                    i == _activiteRecente.length - 1;
                final Color color =
                    act['color'] as Color? ?? primary;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {},
                      borderRadius:
                          BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                              ),
                              child: Icon(
                                act['icon'] as IconData,
                                color: color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    act['titre'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: Color(
                                          0xFF1B2B27),
                                    ),
                                  ),
                                  if ((act['sous'] ?? '')
                                      .isNotEmpty)
                                    Text(
                                      act['sous'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey,
                                size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1,
                          indent: 64,
                          endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Conseil du jour ───────────────────────────────────────────────────────
  Widget _buildConseilDuJour() {
    final conseils = [
      {'texte': 'Buvez au moins 1,5L d\'eau par jour pour rester hydraté et en bonne santé !', 'emoji': '💧'},
      {'texte': 'Mangez 5 fruits et légumes par jour pour un apport optimal en vitamines.', 'emoji': '🥦'},
      {'texte': 'Réduisez le sel : moins de 5g par jour pour protéger votre cœur.', 'emoji': '🧂'},
      {'texte': 'Évitez les sucres raffinés et privilégiez les sucres naturels des fruits.', 'emoji': '🍎'},
      {'texte': 'Un petit-déjeuner équilibré booste votre énergie pour toute la journée.', 'emoji': '🥗'},

      // ── Médicaments ──────────────────────────────────
      {'texte': 'Prenez vos médicaments à heure fixe pour une meilleure efficacité.', 'emoji': '⏰'},
      {'texte': 'Ne doublez jamais une dose oubliée sans avis médical.', 'emoji': '💊'},
      {'texte': 'Conservez vos médicaments à l\'abri de la chaleur et de l\'humidité.', 'emoji': '🌡️'},
      {'texte': 'Lisez toujours la notice avant de prendre un nouveau médicament.', 'emoji': '📋'},

      // ── Activité physique ─────────────────────────────
      {'texte': 'Une marche de 30 minutes par jour réduit le risque de maladies cardiaques.', 'emoji': '🚶'},
      {'texte': '150 minutes d\'activité modérée par semaine suffisent pour rester en bonne santé.', 'emoji': '🏃'},
      {'texte': 'Étirez-vous 10 minutes chaque matin pour prévenir les douleurs musculaires.', 'emoji': '🧘'},
      {'texte': 'Prendre les escaliers plutôt que l\'ascenseur est déjà un excellent exercice !', 'emoji': '🏋️'},

      // ── Sommeil ───────────────────────────────────────
      {'texte': 'Dormez 7 à 8 heures par nuit pour renforcer votre système immunitaire.', 'emoji': '😴'},
      {'texte': 'Éteignez les écrans 1h avant de dormir pour améliorer la qualité de votre sommeil.', 'emoji': '📵'},
      {'texte': 'Un sommeil régulier aide à maintenir un poids santé et réduire le stress.', 'emoji': '🌙'},

      // ── Mental & stress ───────────────────────────────
      {'texte': 'Évitez le stress : pratiquez la respiration profonde chaque matin.', 'emoji': '🧘'},
      {'texte': 'Parlez à un proche de vos inquiétudes : le soutien social est essentiel.', 'emoji': '🤝'},
      {'texte': 'Prenez 5 minutes par jour pour noter 3 choses positives de votre journée.', 'emoji': '✍️'},
      {'texte': 'Le rire est un excellent remède : il réduit le cortisol et booste les défenses.', 'emoji': '😄'},

      // ── Prévention ────────────────────────────────────
      {'texte': 'Faites vos contrôles médicaux annuels même si vous vous sentez bien.', 'emoji': '🩺'},
      {'texte': 'Lavez-vous les mains régulièrement : c\'est le geste préventif le plus efficace.', 'emoji': '🧼'},
      {'texte': 'Ne fumez pas : le tabac est responsable de nombreuses maladies graves.', 'emoji': '🚭'},
      {'texte': 'Protégez votre peau du soleil avec un indice SPF adapté toute l\'année.', 'emoji': '☀️'},
      {'texte': 'Consultez un ophtalmologue tous les 2 ans pour surveiller votre vue.', 'emoji': '👁️'},

      // ── Santé bucco-dentaire ──────────────────────────
      {'texte': 'Brossez vos dents 2 fois par jour pendant au moins 2 minutes.', 'emoji': '🦷'},
      {'texte': 'Visitez votre dentiste au moins une fois par an, même sans douleur.', 'emoji': '🦷'},

      // ── Posture & ergonomie ───────────────────────────
      {'texte': 'Faites une pause de 5 minutes toutes les heures si vous travaillez assis.', 'emoji': '💺'},
      {'texte': 'Adoptez une bonne posture : dos droit, épaules détendues, pieds à plat.', 'emoji': '🪑'},

      // ── Cardio & tension ──────────────────────────────
      {'texte': 'Mesurez votre tension régulièrement, surtout après 40 ans.', 'emoji': '❤️'},
      {'texte': 'Un cœur sain commence par une alimentation pauvre en graisses saturées.', 'emoji': '🫀'},
    ];

    // ✅ Conseil différent chaque jour de l'année
    final index = DateTime.now().dayOfYear % conseils.length;
    final conseil = conseils[index];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                conseil['emoji']!,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Conseil du jour',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            conseil['texte']!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _sourceColor(String source) {
    switch (source) {
      case 'chronique':
        return Colors.orange;
      case 'consultation':
        return primary;
      default:
        return Colors.purple;
    }
  }

  String _moisCourt(int m) {
    const mois = [
      'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN',
      'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC'
    ];
    return mois[m - 1];
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS HELPERS
// ══════════════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: active
                ? [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: active
                  ? FontWeight.w700
                  : FontWeight.w500,
              fontSize: 14,
              color: active
                  ? const Color(0xFF1BC2AB)
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2B27),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.4), size: 28),
          const SizedBox(width: 14),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

extension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays;
  }
}