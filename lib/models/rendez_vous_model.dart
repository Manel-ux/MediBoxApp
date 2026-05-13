//lib/models/rendez_vous_model.dart

class RendezVousModel {
  final String id;          // id_rdv
  final DateTime date;
  final String motif;
  final String lieu;
  final String idPatient;
  final String idMedecin;

  // Données enrichies (jointure côté app)
  final String? nomMedecin;
  final String? specialiteMedecin;

  RendezVousModel({
    required this.id,
    required this.date,
    required this.motif,
    this.lieu = '',
    required this.idPatient,
    required this.idMedecin,
    this.nomMedecin,
    this.specialiteMedecin,
  });

  factory RendezVousModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return RendezVousModel(
      id: id ?? map['id_rdv'] ?? '',
      date: map['date']?.toDate() ?? DateTime.now(),
      motif: map['motif'] ?? '',
      lieu: map['lieu'] ?? '',
      idPatient: map['id_patient'] ?? '',
      idMedecin: map['id_medecin'] ?? '',
      nomMedecin: map['nom_medecin'],
      specialiteMedecin: map['specialite_medecin'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id_rdv': id,
    'date': date,
    'motif': motif,
    'lieu': lieu,
    'id_patient': idPatient,
    'id_medecin': idMedecin,
  };

  bool get estPasse => date.isBefore(DateTime.now());
  bool get estAujourd => date.day == DateTime.now().day &&
      date.month == DateTime.now().month &&
      date.year == DateTime.now().year;
  bool get estFutur => date.isAfter(DateTime.now());
}