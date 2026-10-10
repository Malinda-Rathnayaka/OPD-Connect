import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final double distance;
  final bool isOpen;
  final List<String> clinics;
  final DateTime? nextSession;
  final String phone;

  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.distance,
    required this.isOpen,
    required this.clinics,
    required this.nextSession,
    required this.phone,
  });

  factory HospitalModel.fromMap(Map<String, dynamic> map, String id) {
    final dynamic nextSessionValue = map['nextSession'];

    return HospitalModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      isOpen: map['isOpen'] ?? false,
      clinics: (map['clinics'] as List<dynamic>? ?? const [])
          .map((clinic) => clinic.toString())
          .toList(),
      nextSession: nextSessionValue is Timestamp
          ? nextSessionValue.toDate()
          : nextSessionValue is DateTime
              ? nextSessionValue
              : null,
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'distance': distance,
      'isOpen': isOpen,
      'clinics': clinics,
      'nextSession': nextSession != null
          ? Timestamp.fromDate(nextSession!)
          : null,
      'phone': phone,
    };
  }

  HospitalModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    double? distance,
    bool? isOpen,
    List<String>? clinics,
    DateTime? nextSession,
    String? phone,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      distance: distance ?? this.distance,
      isOpen: isOpen ?? this.isOpen,
      clinics: clinics ?? this.clinics,
      nextSession: nextSession ?? this.nextSession,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() {
    return 'HospitalModel(id: $id, name: $name, address: $address, city: $city, distance: $distance, isOpen: $isOpen, clinics: $clinics, nextSession: $nextSession, phone: $phone)';
  }
}
