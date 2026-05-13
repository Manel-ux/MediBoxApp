import 'package:carnetdesante/services/auth_service.dart';
import 'package:carnetdesante/views/auth/register_swipe_screen.dart';
import 'package:carnetdesante/views/main_navigation_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; 
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Container(
              height: 410,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bienvenue.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(27.0),
              child: Column(
                children: [
                  // Champ Nom d'utilisateur
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Nom d'utilisateur",
                      filled: true,
                      fillColor: const Color.fromARGB(29, 215, 215, 215),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Champ Mot de passe
                  TextField(
                    controller: _passwordController,                    
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      filled: true,
                      fillColor: const Color.fromARGB(29, 215, 215, 215),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.lock),
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
                  ),
                  const SizedBox(height: 30),

                  // Bouton de connexion
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        String username = _usernameController.text.trim();
                        String password = _passwordController.text.trim();

                        if (username.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Veuillez remplir tous les champs"))
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        String? error = await AuthService().loginWithUsername(username, password);

                        setState(() => _isLoading = false);

                        if (error == null) {
                          if (mounted) {
                            Navigator.pushReplacement(
                              // ignore: use_build_context_synchronously
                              context, 
                              MaterialPageRoute(builder: (context) => const MainNavigationScreen())
                            );
                          }
                        } else {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: const Color.fromARGB(255, 205, 41, 29))
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 27, 194, 171),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Se connecter", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Lien vers l'inscription
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterSwipeScreen()),
                        );
                      },
                      child: const Text("Pas de compte ? Inscrivez-vous ici"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}