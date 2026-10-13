import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Create the account once and use Firebase's built-in verification email.
  Future<void> createAccountAndSendVerification({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-registration-data');
    }

    // Registration must not reuse a different signed-in account or silently
    // sign in to an account that already exists.
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final currentUser = credential.user;
    if (currentUser == null) {
      throw FirebaseAuthException(code: 'user-not-created');
    }

    await currentUser.sendEmailVerification();
  }

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    await user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Save the profile after Firebase confirms the email address.
  Future<void> completeUserRegistration({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String registrationNumber = '',
    String department = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    if (!{'patient', 'doctor'}.contains(role)) {
      throw ArgumentError.value(
        role,
        'role',
        'Only patients and doctors can register here.',
      );
    }

    final emailAddress = user.email ?? email.trim().toLowerCase();
    final isDoctor = role == 'doctor';
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    final profile = <String, dynamic>{
      'role': role,
      'name': name,
      'fullName': name,
      'email': emailAddress,
      'phone': phone,
      'isVerified': !isDoctor,
      'isApproved': !isDoctor,
      'createdAt': now,
    };

    final userData = {
      'email': user.email ?? email,
      'phone': phone,
      'name': name,
      'role': role,
      'isActive': true,
      if (isDoctor) 'registrationNumber': registrationNumber.trim(),
      if (isDoctor) 'department': department.trim(),
      'isVerified': role == 'patient',
      'isApproved': role != 'doctor',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (isDoctor) {
      batch.set(_db.collection('doctors').doc(user.uid), {
        ...profile,
        'specialization': '',
        'roomNo': '',
        'registrationNumber': registrationNumber.trim(),
        'department': department.trim(),
      });
    } else {
      batch.set(_db.collection('patients').doc(user.uid), {
        ...profile,
        'history': <dynamic>[],
        'nic': '',
        'preferredLanguage': 'English',
      });
    }

    // Staff review and role routing share this directory; retain contact and
    // registration fields alongside the role-specific profile.
    batch.set(_db.collection('users').doc(user.uid), userData);
    await batch.commit();
  }

  /// Load auth metadata and merge in the role-specific profile document.
  Stream<UserModel?> watchUserData(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .asyncMap((snapshot) => _profileFor(uid, snapshot.data()));

  Future<UserModel?> getUserData(String uid) async {
    return _profileFor(uid, (await _db.collection('users').doc(uid).get()).data());
  }

  Future<UserModel?> _profileFor(String uid, Map<String, dynamic>? metadata) async {
    if (metadata == null) return null;
    final role = metadata['role']?.toString() ?? 'patient';
    final profile = role == 'admin' ? null : (await _db
        .collection(role == 'doctor' ? 'doctors' : 'patients').doc(uid).get()).data();
    final authUser = _auth.currentUser;
    final merged = <String, dynamic>{
      ...?profile,
      ...metadata,
      'role': role,
      'email': metadata['email'] ?? profile?['email'] ?? authUser?.email ?? '',
      'isVerified': metadata['isVerified'] ?? profile?['isVerified'] ?? true,
      'isApproved':
           metadata['isApproved'] ?? profile?['isApproved'] ?? role != 'doctor',
    };
    return UserModel.fromMap(merged, uid);
  }

  /// Login with Email & Password
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign Out User
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
