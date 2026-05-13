import 'package:carnetdesante/views/home/profile_screen.dart';
import 'package:carnetdesante/views/rappels/rappels_screen.dart';
import 'package:flutter/material.dart';
import 'home/home_screen.dart'; 
import 'home/consultations_screen.dart'; 

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0; 


  final List<Widget> _pages = [
    const HomeScreen(),
    const ConsultationsScreen(),
    const RappelsScreen(),   // ← maintenant c'est le bon import
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; 
    });
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    // IndexedStack est magique : il garde l'état de tes pages !
    body: IndexedStack(
      index: _selectedIndex,
      children: _pages,
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed, // Recommandé pour 4 items et plus
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
  }}