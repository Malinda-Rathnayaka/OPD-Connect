class UserModel {
  final String uid;
  final String emailOrPhone;
  final String email;
  final String phone;
  final String name;
  final String role; // 'patient', 'doctor', 'admin'
  final bool isVerified;
  final bool isApproved; // Admin approval flag for doctors
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    this.emailOrPhone = '',
    this.email = '',
    this.phone = '',
    required this.name,
    required this.role,
    this.isVerified = true,
    this.isApproved = true,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      emailOrPhone: map['emailOrPhone'] ?? map['email'] ?? '',
      email: map['email'] ?? map['emailOrPhone'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? map['fullName'] ?? '',
      role: map['role'] ?? 'patient',
      isVerified: map['isVerified'] ?? true,
      isApproved: map['isApproved'] ?? (map['role'] != 'doctor'),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailOrPhone': emailOrPhone,
      'email': email,
      'phone': phone,
      'name': name,
      'role': role,
      'isVerified': isVerified,
      'isApproved': isApproved,
    };
  }

  /// Create a copy with selective field overrides
  UserModel copyWith({
    String? emailOrPhone,
    String? email,
    String? phone,
    String? name,
    String? role,
    bool? isVerified,
    bool? isApproved,
  }) {
    return UserModel(
      uid: uid,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt,
    );
  }
}
