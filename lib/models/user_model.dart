class UserModel {
  final String uid;
  final String emailOrPhone;
  final String email;
  final String phone;
  final String name;
  final String role; // 'patient', 'doctor', 'admin'
  final bool isVerified;
  final bool isApproved; // Admin approval flag for doctors
  final bool isActive;
  final String approvalStatus;
  final String reviewNote;
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
    this.isActive = true,
    this.approvalStatus = '',
    this.reviewNote = '',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      emailOrPhone: map['emailOrPhone'] ?? map['email'] ?? '',
      email: map['email'] ?? map['emailOrPhone'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      isVerified: map['isVerified'] ?? true,
      isApproved: map['isApproved'] ?? (map['role'] != 'doctor'),
      isActive: map['isActive'] ?? true,
      approvalStatus: map['approvalStatus'] ?? '',
      reviewNote: map['reviewNote'] ?? '',
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
      'isActive': isActive,
      'approvalStatus': approvalStatus,
      'reviewNote': reviewNote,
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
    bool? isActive,
    String? approvalStatus,
    String? reviewNote,
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
      isActive: isActive ?? this.isActive,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reviewNote: reviewNote ?? this.reviewNote,
      createdAt: createdAt,
    );
  }
}
