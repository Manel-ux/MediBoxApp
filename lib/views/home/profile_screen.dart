import 'package:carnetdesante/sante/mensurartion_screen.dart';
import 'package:carnetdesante/views/auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primary = Color(0xFF1BC2AB);
  final User? user = FirebaseAuth.instance.currentUser;

  String _prenom = '';
  String _nom = '';
  String _email = '';
  String _groupeSanguin = '';
  String _sexe = '';
  String _dateNaissance = '';
  String _telephone = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final uid = user?.uid ?? '';

      DocumentSnapshot snap;
      try {
        snap = await FirebaseFirestore.instance
            .collection('Dossier_Medical')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        snap = await FirebaseFirestore.instance
            .collection('Dossier_Medical')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
      }

      final d = snap.data() as Map<String, dynamic>? ?? {};

      _prenom        = d['prenom']?.toString()        ?? '';
      _nom           = d['nom']?.toString()            ?? '';
      _email         = d['email']?.toString()          ?? '';
      _groupeSanguin = d['groupeSanguin']?.toString()  ?? '';
      _sexe          = d['sexe']?.toString()           ?? '';
      _dateNaissance = (d['dateNaissance'] ?? d['date_naissance'])
                           ?.toString() ?? '';
      _telephone     = d['telephone']?.toString()      ?? '';

      // Fallback displayName
      if (_prenom.isEmpty &&
          (user?.displayName?.isNotEmpty ?? false)) {
        final parts = user!.displayName!.trim().split(' ');
        _prenom = parts.first;
        _nom = parts.length > 1
            ? parts.sublist(1).join(' ')
            : '';
      }
    } catch (e) {
      debugPrint('Erreur profil : $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deconnecter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text(
            'Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String get _nomComplet {
    final full = '$_prenom $_nom'.trim();
    if (full.isNotEmpty) return full;
    return _email.split('@').first;
  }

  String get _username {
    final rawEmail = user?.email ?? '';
    if (rawEmail.contains('@carnetsante.dz')) {
      return '@${rawEmail.split('@').first}';
    }
    if (_prenom.isNotEmpty) {
      return '@${_prenom.toLowerCase()}';
    }
    return '@${rawEmail.split('@').first}';
  }

  String get _initiales {
    final p = _prenom.isNotEmpty ? _prenom[0] : '';
    final n = _nom.isNotEmpty ? _nom[0] : '';
    if (p.isEmpty && n.isEmpty && _email.isNotEmpty) {
      return _email[0].toUpperCase();
    }
    return '$p$n'.toUpperCase();
  }

  String _membreDepuis() {
    final creation = user?.metadata.creationTime;
    if (creation == null) return '';
    const mois = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${mois[creation.month - 1]} ${creation.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              color: primary,
              child: CustomScrollView(
                slivers: [
                  // ── AppBar ──────────────────────────
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    title: const Text(
                      'Profil',
                      style: TextStyle(
                        color: Color(0xFF1B2B27),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: primary),
                        onPressed: _charger,
                      ),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),

                        // ── Carte identité ──────────────
                        _buildIdentiteCard(),
                        const SizedBox(height: 16),

                        // ── Infos personnelles ──────────
                        _buildInfosCard(),
                        const SizedBox(height: 16),

                        // ── Mes données ─────────────────
                        _buildSection(items: [
                          _MenuItem(
                            icon: Icons.monitor_heart_outlined,
                            color: Colors.purple,
                            label: 'Mes mensurations',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MensurationsScreen()),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // ── Paramètres ──────────────────
                        _buildSection(items: [
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            color: Colors.grey,
                            label: 'Paramètres',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            color: Colors.grey,
                            label: 'Notifications',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.privacy_tip_outlined,
                            color: Colors.grey,
                            label: 'Confidentialité',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.help_outline,
                            color: Colors.grey,
                            label: 'Aide & Support',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // ── Infos app ───────────────────
                        _buildSection(items: [
                          _MenuItem(
                            icon: Icons.info_outline,
                            color: Colors.grey,
                            label: 'Version',
                            trailing: const Text(
                              '1.0.0',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13),
                            ),
                            isInfo: true,
                          ),
                          if (_membreDepuis().isNotEmpty)
                            _MenuItem(
                              icon: Icons
                                  .calendar_today_outlined,
                              color: Colors.grey,
                              label:
                                  'Membre depuis ${_membreDepuis()}',
                              isInfo: true,
                            ),
                        ]),
                        const SizedBox(height: 16),

                        // ── Déconnexion ─────────────────
                        _buildSection(items: [
                          _MenuItem(
                            icon: Icons.logout,
                            color: Colors.red,
                            label: 'Se déconnecter',
                            labelColor: Colors.red,
                            onTap: _deconnecter,
                            showArrow: false,
                          ),
                        ]),
                        const SizedBox(height: 24),

                        Center(
                          child: Text(
                            'Carnet de Santé © 2026',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Carte identité ────────────────────────────────────────────────────────
  Widget _buildIdentiteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar initiales
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initiales,
                style: const TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Nom + username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Nom et prénom du patient
                Text(
                  _nomComplet,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2B27),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _username,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                // Badge groupe sanguin
                if (_groupeSanguin.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bloodtype,
                            size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          _groupeSanguin,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Infos personnelles ────────────────────────────────────────────────────
  Widget _buildInfosCard() {
    final items = <Map<String, dynamic>>[];

    if (_sexe.isNotEmpty)
      items.add({
        'icon': Icons.person_outline,
        'label': 'Sexe',
        'value': _sexe,
      });
    if (_dateNaissance.isNotEmpty)
      items.add({
        'icon': Icons.cake_outlined,
        'label': 'Date de naissance',
        'value': _dateNaissance,
      });
    if (_telephone.isNotEmpty)
      items.add({
        'icon': Icons.phone_outlined,
        'label': 'Téléphone',
        'value': _telephone,
      });
    if (_email.isNotEmpty)
      items.add({
        'icon': Icons.email_outlined,
        'label': 'E-mail',
        'value': _email,
      });

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
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
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            item['value'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1B2B27),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, indent: 62, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Section générique ─────────────────────────────────────────────────────
  Widget _buildSection({required List<_MenuItem> items}) {
    return Container(
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
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.isInfo ? null : item.onTap,
                borderRadius: BorderRadius.only(
                  topLeft: i == 0
                      ? const Radius.circular(16)
                      : Radius.zero,
                  topRight: i == 0
                      ? const Radius.circular(16)
                      : Radius.zero,
                  bottomLeft: isLast
                      ? const Radius.circular(16)
                      : Radius.zero,
                  bottomRight: isLast
                      ? const Radius.circular(16)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon,
                            color: item.color, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.labelColor ??
                                const Color(0xFF1B2B27),
                          ),
                        ),
                      ),
                      if (item.trailing != null)
                        item.trailing!
                      else if (!item.isInfo && item.showArrow)
                        Icon(Icons.chevron_right,
                            color: Colors.grey[400], size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, indent: 64, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Modèle menu item ──────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final Color color;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isInfo;
  final bool showArrow;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.label,
    this.labelColor,
    this.trailing,
    this.onTap,
    this.isInfo = false,
    this.showArrow = true,
  });
}