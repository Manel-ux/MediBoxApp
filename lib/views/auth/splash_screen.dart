import 'dart:async';
import 'package:flutter/material.dart';
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
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /////////// Icône ou Logo temporaire
            Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/freepik--20260417193755ZD2L.png'),
                  fit: BoxFit.cover
                  // fit: BoxFit.cover,
                  )
              ),
            ),
            const SizedBox(height: 20),

            // Nom de l'application
            
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