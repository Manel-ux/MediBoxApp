import 'dart:async';
import 'package:carnetdesante/views/auth/onboarding_screen.dart';
import 'package:carnetdesante/views/main_navigation_screen.dart';
// import 'package:carnetdesante/views/medical/medical_form_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Attend 3s puis décide où aller
    Timer(const Duration(seconds: 3), () {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    // ✅ Vérifie si l'onboarding a déjà été vu
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingVu = prefs.getBool('onboarding_vu') ?? false;

    if (!onboardingVu) {
      // ✅ Premier lancement → onboarding
      await prefs.setBool('onboarding_vu', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const OnboardingScreen()),
        );
      }
      return;
    }

    // ✅ Onboarding déjà vu → vérifie si connecté
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    // ✅ Connecté → vérifie si dossier complet
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Dossier_Medical')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 6));

      final data = snap.data() ?? {};
      final bool complet =
          (data['groupeSanguin'] ?? '').toString().isNotEmpty;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(
            afficherFormulaire: !complet,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const MainNavigationScreen()),
        );
      }
    }
  }

  // ✅ build() identique à avant — ne change rien ici
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/freepik--20260417193755ZD2L.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 10),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Color.fromARGB(255, 27, 194, 171),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}