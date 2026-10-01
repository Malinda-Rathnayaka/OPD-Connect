class UserModel {
  final String uid;
  final String emailOrPhone;
  final String name;
  final String role; // 'patient', 'doctor', 'admin'
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.emailOrPhone,
    required this.name,
    required this.role,
    this.isVerified = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      emailOrPhone: map['emailOrPhone'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      isVerified: map['isVerified'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailOrPhone': emailOrPhone,
      'name': name,
      'role': role,
      'isVerified': isVerified,
    };
  }
}