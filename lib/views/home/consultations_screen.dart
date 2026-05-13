// ignore_for_file: unnecessary_underscores

import 'package:carnetdesante/views/home/add_consultation_stepper.dart';
import 'package:carnetdesante/views/home/consultation_detail_screen.dart'; // ← nouveau
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Consultations',
          style: TextStyle(
              color: Color(0xFF1B2B27),
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        actions: [
          // ✅ Bouton + Nouvelle en haut à droite
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddConsultationStepper()),
                );
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Nouvelle',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BC2AB),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher une consultation...',
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

          // ✅ Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Dossier_Medical')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('Consultations')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _EmptyConsultations();
                }

                var docs = snapshot.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                final motif   = (data['motif']          ?? '').toLowerCase();
                final diag    = (data['diagnostic']     ?? '').toLowerCase();
                final obs     = (data['observations']   ?? '').toLowerCase();
                final date    = (data['date']           ?? '').toLowerCase();
                final prenom  = (data['medecinPrenom']  ?? '').toLowerCase();
                final nom     = (data['medecinNom']     ?? '').toLowerCase();
                return motif.contains(q)  ||
                      diag.contains(q)   ||
                      obs.contains(q)    ||
                      date.contains(q)   ||  // ✅ recherche par date
                      prenom.contains(q) ||
                      nom.contains(q);
              }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text('Aucun résultat pour "$_searchQuery"',
                        style: const TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 70,
                    endIndent: 16,
                    color: Color(0xFFEEEEEE),),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _ConsultationTile(
                      data: data,
                      docId: docId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Ajoute dans la classe State :
  String _searchQuery = '';
}

// ── Consultation Tile ─────────────────────────────────────────────────────────
class _ConsultationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _ConsultationTile(
      {required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final String motif    = data['motif']     ?? 'Consultation';
    final String diag     = data['diagnostic'] ?? '';
    final String date     = data['date']      ?? '';
    final String prenom   = data['medecinPrenom'] ?? '';
    final String nom      = data['medecinNom']    ?? '';
    final String medecin  = '$prenom $nom'.trim();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultationDetailScreen(
            docId: docId,
            consultationData: data,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Icône calendrier colorée
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1BC2AB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF1BC2AB),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Date en petit au-dessus
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // ✅ Motif en gros — titre principal
                  Text(
                    motif,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2B27),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ✅ Médecin avec icône
                  if (medecin.trim().isNotEmpty)
                    Row(children: [
                      Icon(Icons.person_outline,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 5),
                      Text(
                        medecin.trim().toLowerCase().startsWith('dr')
                            ? medecin.trim()
                            : 'Dr. ${medecin.trim()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),

                  // ✅ Diagnostic avec icône
                  if (diag.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_outlined,
                            size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            diag,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ✅ Flèche droite
            const Icon(Icons.chevron_right,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Empty consultations ───────────────────────────────────────────────────────
class _EmptyConsultations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Remplace par ton image ici :
          Image.asset('assets/images/consultation.png', width: 200),
          // Icon(Icons.medical_services_outlined,
          //     size: 90, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('Aucune consultation',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2B27))),
          const SizedBox(height: 8),
          Text('Ajoutez votre première consultation',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }
}