// lib/models/medecin_model.dart

class MedecinModel {
  final String id;          // id_medecin
  final String nom;
  final String prenom;
  final String specialite;
  final String telephone;
  final String adresseCabinet;

  MedecinModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.specialite,
    this.telephone = '',
    this.adresseCabinet = '',
  });

  factory MedecinModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MedecinModel(
      id: id ?? map['id_medecin'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      specialite: map['specialite'] ?? '',
      telephone: map['telephone'] ?? '',
      adresseCabinet: map['adresse_cabinet'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id_medecin': id,
    'nom': nom,
    'prenom': prenom,
    'specialite': specialite,
    'telephone': telephone,
    'adresse_cabinet': adresseCabinet,
  };

  String get nomComplet => 'Dr. $prenom $nom';
  String get affichage => 'Dr. $prenom $nom — $specialite';
}