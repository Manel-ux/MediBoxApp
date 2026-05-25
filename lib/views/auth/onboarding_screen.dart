import 'package:carnetdesante/views/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;
  static const Color primary = Color(0xFF1BC2AB);

  final List<_SlideData> _slides = [
    _SlideData(
      image: 'assets/images/Gemini_Generated_Image_mr48mrmr48mrmr48 (3).png',
      titre: 'Votre santé, sécurisée',
      sousTitre:
          'Toutes vos données médicales sont chiffrées et protégées. Seul vous y avez accès.',
    ),
    _SlideData(
      image: 'assets/images/alarme2.png',
      titre: 'Rappels intelligents',
      sousTitre:
          'Ne manquez plus jamais une prise de médicament ou un rendez-vous médical grâce à nos alertes personnalisées.',
    ),
    _SlideData(
      image: 'assets/images/undraw_medicine_hqqg.svg',
      isSvg: false,
      isPng: true,
      titre: 'Dossier médical complet',
      sousTitre:
          'Consultations, ordonnances, examens et historique médical — tout en un seul endroit.',
    ),
  ];

  void _suivant() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      _naviguerLogin();
    }
  }

  void _naviguerLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Bouton passer ─────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: TextButton(
                  onPressed: _naviguerLogin,
                  child: Text(
                    'Passer',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // ── Slides ────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) =>
                    _buildSlide(_slides[i]),
              ),
            ),

            // ── Indicateurs ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Bouton suivant / commencer ─────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _suivant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    _page == _slides.length - 1
                        ? 'Commencer'
                        : 'Suivant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Image ──────────────────────────────────
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              // ✅ APRÈS — gère PNG et SVG automatiquement
              child: slide.image.endsWith('.svg')
                  ? SvgPicture.asset(
                      slide.image,
                      fit: BoxFit.contain,
                    )
                  : Image.asset(
                      slide.image,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Titre ──────────────────────────────────
          Text(
            slide.titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2B27),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // ── Sous-titre ─────────────────────────────
          Text(
            slide.sousTitre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SlideData {
  final String image;
  final String titre;
  final String sousTitre;
  final bool isSvg;
  final bool isPng;

  const _SlideData({
    required this.image,
    required this.titre,
    required this.sousTitre,
    this.isSvg = false,
    this.isPng = false,
  });
}