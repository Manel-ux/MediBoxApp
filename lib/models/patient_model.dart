// lib/models/patient_model.dart

class PatientModel {
  final String id;          // id_patient (Firebase UID)
  final String nom;
  final String prenom;
  final String sexe;
  final String groupeSanguin;
  final String dateNaissance;
  final String telephone;
  final String email;
  final String nss;
  final String username;

  PatientModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.sexe,
    this.groupeSanguin = '',
    required this.dateNaissance,
    required this.telephone,
    this.email = '',
    this.nss = '',
    required this.username,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return PatientModel(
      id: id ?? map['id_patient'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      sexe: map['sexe'] ?? '',
      groupeSanguin: map['groupe_sanguin'] ?? '',
      dateNaissance: map['date_naissance'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      nss: map['NSS'] ?? '',
      username: map['username'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id_patient': id,
    'nom': nom,
    'prenom': prenom,
    'sexe': sexe,
    'groupe_sanguin': groupeSanguin,
    'date_naissance': dateNaissance,
    'telephone': telephone,
    'email': email,
    'NSS': nss,
    'username': username,
  };

  PatientModel copyWith({
    String? nom,
    String? prenom,
    String? sexe,
    String? groupeSanguin,
    String? dateNaissance,
    String? telephone,
    String? email,
    String? nss,
  }) {
    return PatientModel(
      id: id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      sexe: sexe ?? this.sexe,
      groupeSanguin: groupeSanguin ?? this.groupeSanguin,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      nss: nss ?? this.nss,
      username: username,
    );
  }

  String get nomComplet => '$prenom $nom';
}