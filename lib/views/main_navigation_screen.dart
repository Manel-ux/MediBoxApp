import 'package:carnetdesante/views/home/profile_screen.dart';
import 'package:carnetdesante/views/rappels/rappels_screen.dart';
import 'package:carnetdesante/views/medical/medical_form_overlay.dart'; // ✅ AJOUTER
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'home/consultations_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool afficherFormulaire; // ✅ AJOUTER

  const MainNavigationScreen({
    super.key,
    this.afficherFormulaire = false, // ✅ AJOUTER
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ConsultationsScreen(),
    const RappelsScreen(),
    const ProfileScreen(),
  ];

  // ✅ AJOUTER initState complet
  @override
  void initState() {
    super.initState();
    if (widget.afficherFormulaire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => const MedicalFormOverlay(),
        );
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1BC2AB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Consultations'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Rappels'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}