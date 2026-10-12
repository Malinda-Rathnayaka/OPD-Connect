class PatientModel {
  final String id;
  final String fullName;
  final String nic;
  final String phone;
  final String email;
  final List<dynamic> history;

  PatientModel({
    required this.id,
    required this.fullName,
    required this.nic,
    required this.phone,
    required this.email,
    required this.history,
  });

  factory PatientModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PatientModel(
      id: id,
      fullName: data['fullName'] ?? 'Unknown Patient',
      nic: data['nic'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      history: data['history'] ?? [],
    );
  }
}