import 'package:flutter/material.dart';

enum AccountStatus { active, pending, rejected, inactive }

class StaffAccount {
  final String id, name, email, phone, role, department, registration, nic;
  final String staffRole, reviewNote, approvalStatus;
  final bool active, approved;
  final DateTime? createdAt;

  const StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.department = '',
    this.registration = '',
    this.nic = '',
    this.staffRole = 'Hospital administrator',
    this.reviewNote = '',
    this.approvalStatus = '',
    this.active = true,
    this.approved = true,
    this.createdAt,
  });

  factory StaffAccount.fromMap(String id, Map<String, dynamic> data) {
    final stamp = data['createdAt'];
    return StaffAccount(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? data['emailOrPhone'] ?? '',
      role: data['role'] ?? 'patient',
      phone: data['phone'] ?? '',
      department: data['department'] ?? '',
      registration: data['registrationNumber'] ?? '',
      nic: data['nic'] ?? '',
      staffRole: data['staffRole'] ?? 'Hospital administrator',
      reviewNote: data['reviewNote'] ?? '',
      approvalStatus: data['approvalStatus'] ?? '',
      active: data['isActive'] ?? true,
      approved: data['isApproved'] ?? (data['role'] != 'doctor'),
      createdAt: stamp == null ? null : (stamp as dynamic).toDate(),
    );
  }

  AccountStatus get status {
    if (!active) return AccountStatus.inactive;
    if (role == 'doctor' && !approved) {
      return approvalStatus == 'rejected' || reviewNote.startsWith('Rejected:')
          ? AccountStatus.rejected
          : AccountStatus.pending;
    }
    return AccountStatus.active;
  }

  String get roleLabel => switch (role) {
    'doctor' => 'Doctor',
    'admin' => 'Hospital staff',
    _ => 'Patient',
  };

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && word != 'Dr.')
      .take(2)
      .map((word) => word[0])
      .join()
      .toUpperCase();

  StaffAccount withChanges(Map<String, dynamic> changes) => StaffAccount(
    id: id,
    name: changes['name'] ?? name,
    email: email,
    role: role,
    phone: changes['phone'] ?? phone,
    department: changes['department'] ?? department,
    registration: registration,
    nic: nic,
    staffRole: changes['staffRole'] ?? staffRole,
    reviewNote: changes['reviewNote'] ?? reviewNote,
    approvalStatus: changes['approvalStatus'] ?? approvalStatus,
    active: changes['isActive'] ?? active,
    approved: changes['isApproved'] ?? approved,
    createdAt: createdAt,
  );
}

class Department {
  final String id, name, location;
  final bool active;
  const Department(this.id, this.name, this.location, {this.active = true});
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'active': active,
  };
  factory Department.fromMap(Map<String, dynamic> data) => Department(
    data['id'],
    data['name'],
    data['location'],
    active: data['active'] ?? true,
  );
}

class StaffActivity {
  final String title, detail, actor;
  final DateTime time;
  const StaffActivity(this.title, this.detail, this.actor, this.time);
}

class OperationsAlert {
  final String id, title, detail, action;
  final bool warning;
  bool acknowledged;
  OperationsAlert(
    this.id,
    this.title,
    this.detail,
    this.action, {
    this.warning = true,
    this.acknowledged = false,
  });
}

abstract final class StaffStyle {
  static const ink = Color(0xFF18332F);
  static const muted = Color(0xFF6B7F7A);
  static const green = Color(0xFF087F68);
  static const canvas = Color(0xFFF5F8F7);
  static const line = Color(0xFFE2EBE7);
  static const mint = Color(0xFFE8F5EF);
  static const amber = Color(0xFFA8680D);
  static const red = Color(0xFFB94747);

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: Colors.white,
    ),
    fontFamily: 'Segoe UI',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.8,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: muted, height: 1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
      hintStyle: const TextStyle(color: muted, fontSize: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: line),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
  );
}
