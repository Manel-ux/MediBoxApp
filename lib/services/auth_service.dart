import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── 1. Vérifie si le username existe ─────────────────
  Future<bool> isUsernameTaken(String username) async {
    final result = await _db
        .collection('Patient')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty;
  }

  // ── 2. Inscription ────────────────────────────────────
  Future<String?> registerStep1({
    required String username,
    required String password,
  }) async {
    try {
      if (await isUsernameTaken(username)) {
        return "Ce nom d'utilisateur est déjà utilisé.";
      }
      final fakeEmail = "$username@carnetsante.dz";
      await _auth.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // ── 3. Profil patient + Dossier médical ───────────────
  Future<String?> savePatientProfile({
    required String username,
    required String nom,
    required String prenom,
    required String dateNaissance,
    required String sexe,
    required String telephone,
    required String emailReel,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Utilisateur non connecté';

      // ✅ Met à jour le displayName Firebase Auth
      await user.updateDisplayName('$prenom $nom');

      // ✅ Collection Patient
      await _db.collection('Patient').doc(user.uid).set({
        'id_patient':     user.uid,
        'nom':            nom,
        'prenom':         prenom,
        'sexe':           sexe,
        'date_naissance': dateNaissance,
        'telephone':      telephone,
        'email':          emailReel,
        'username':       username,
        'groupe_sanguin': '',
        'NSS':            '',
      });

      // ✅ Dossier médical avec l'UID comme clé
      await _db.collection('Dossier_Medical').doc(user.uid).set({
        'id_patient':      user.uid,
        'nom':             nom,
        'prenom':          prenom,
        'sexe':            sexe,
        'dateNaissance':   dateNaissance,
        'telephone':       telephone,
        'email':           emailReel,
        'username':        username,
        'groupeSanguin':   '',
        'date_creation':   FieldValue.serverTimestamp(),
        'statut':          'Actif',
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── 4. Connexion ──────────────────────────────────────
  Future<String?> loginWithUsername(
      String username, String password) async {
    try {
      final fakeEmail = "$username@carnetsante.dz";
      await _auth.signInWithEmailAndPassword(
        email:    fakeEmail,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return "Nom d'utilisateur ou mot de passe incorrect.";
      }
      return "Erreur : ${e.message}";
    }
  }

  // ── 5. Déconnexion ────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }
}