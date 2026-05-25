import 'package:carnetdesante/services/auth_service.dart';
import 'package:carnetdesante/views/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RegisterSwipeScreen extends StatefulWidget {
  const RegisterSwipeScreen({super.key});

  @override
  State<RegisterSwipeScreen> createState() => _RegisterSwipeScreenState();
}

class _RegisterSwipeScreenState extends State<RegisterSwipeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // --- CONTRÔLEURS ---
  // Page 1: Identifiants
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Page 2: Informations personnelles (Uniquement celles demandées)
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedSexe = "Masculin"; // Valeur par défaut

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _handleNextStep() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPage == 0) {
        _showLoading();
        // Vérification du pseudo
        bool taken = await _authService.isUsernameTaken(_usernameController.text.trim().toLowerCase());
        if (!mounted) return;
        Navigator.pop(context);

        if (taken) {
          _showError("Ce nom d'utilisateur est déjà pris.");
        } else {
          _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      } else {
        _finishRegistration();
      }
    }
  }

  void _finishRegistration() async {
    _showLoading();

    // 1. Création du compte Auth
    String? resultAuth = await _authService.registerStep1(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (resultAuth == null) {
      // 2. Enregistrement des infos personnelles précises
      String? resultData = await _authService.savePatientProfile(
        username: _usernameController.text.trim(),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        dateNaissance: _dobController.text.trim(),
        sexe: _selectedSexe,
        telephone: _telController.text.trim(),
        emailReel: _emailController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (resultData == null) {
  // ✅ Passe afficherFormulaire: true pour déclencher le formulaire
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const MainNavigationScreen(
        afficherFormulaire: true, // ✅ formulaire s'affiche une fois
      ),
    ),
    (route) => false,
  );
} else {
  _showError(resultData);
}
    } else {
      if (!mounted) return;
      Navigator.pop(context);
      _showError(resultAuth);
    }
  }

  void _showLoading() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1BC2AB)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) => setState(() => _currentPage = page),
                children: [
                  // PAGE 1 : LOGIN INFOS
                  _buildPage(title: "Créer un compte", subtitle: "Étape 1/2", fields: [
                    TextFormField(
                      controller: _usernameController,
                     // Force le clavier en minuscules
                      keyboardType: TextInputType.emailAddress, 
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')), // Interdit les espaces
                        LowerCaseTextFormatter(), // Force les minuscules pendant la saisie (voir code plus bas)
                      ],
                      decoration: _inputStyle("Nom d'utilisateur", Icons.person), // Icône @ style Insta
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Le nom d'utilisateur est obligatoire";
                        }
                        if (v.length < 3) {
                          return "Minimum 3 caractères";
                        }
                        if (v.length > 30) {
                          return "Le nom est trop long (max 30)";
                        }
                        // Règle Instagram : Lettres, chiffres, points et underscores uniquement
                        if (!RegExp(r'^[a-z0-9._]+$').hasMatch(v)) {
                          return "Utilise uniquement lettres, chiffres, '.' et '_'";
                        }
                      // Règle Instagram : Ne pas commencer ou finir par un point
                        if (v.startsWith('.') || v.endsWith('.')) {
                          return "Le nom ne peut pas commencer ou finir par un point";
                        }
                      // Règle Instagram : Pas de points successifs
                        if (v.contains('..')) {
                          return "Le nom ne peut pas contenir deux points successifs";
                        }
                    return null;
                  },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputStyle("Mot de passe", Icons.lock).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? "Min 6 caractères" : null,
),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPasswordController, 
                      obscureText: !_isConfirmPasswordVisible, 
                      decoration: _inputStyle("Confirmer le mot de passe", Icons.lock_reset).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible? Icons.visibility :Icons.visibility_off),
                          onPressed:(){ setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                          },
                        ),
                      ), 
                      validator: (v) => v != _passwordController.text ? "Les mots de passe diffèrent" : null),
                  ]),

                  // PAGE 2 : INFOS PERSONNELLES
                  _buildPage(title: "Vos Informations", subtitle: "Étape 2/2", fields: [
                    TextFormField(controller: _nomController, decoration: _inputStyle("Nom", Icons.badge), validator: (v) => v!.isEmpty ? "Champ requis" : null),
                    const SizedBox(height: 15),
                    TextFormField(controller: _prenomController, decoration: _inputStyle("Prénom", Icons.badge_outlined), validator: (v) => v!.isEmpty ? "Champ requis" : null),
                    const SizedBox(height: 15),
                    TextFormField(controller: _dobController, readOnly: true, onTap: () => _selectDate(context), decoration: _inputStyle("Date de naissance", Icons.calendar_today), validator: (v) => v!.isEmpty ? "Champ requis" : null),
                    const SizedBox(height: 15),
                    DropdownButtonFormField(initialValue: _selectedSexe, decoration: _inputStyle("Sexe", Icons.wc), items: ["Masculin", "Féminin"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _selectedSexe = v.toString()),),
                    const SizedBox(height: 15),
                    TextFormField(controller: _telController, decoration: _inputStyle("Téléphone", Icons.phone), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? "Champ requis" : null),
                    const SizedBox(height: 15),
                    TextFormField(controller: _emailController, decoration: _inputStyle("E-mail", Icons.email),validator: (v) => v!.isEmpty ? "Champ requis" : null),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleNextStep,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1BC2AB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: Text(_currentPage == 0 ? "Suivant" : "S'inscrire", style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required String title, required String subtitle, required List<Widget> fields}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(children: [
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        ...fields,
      ]),
    );
  }
}


// Petit utilitaire pour forcer la saisie en minuscules
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}