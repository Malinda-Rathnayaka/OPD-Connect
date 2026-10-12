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
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    if (!{'patient', 'doctor'}.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Only patients and doctors can register here.');
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
      'isVerified': role == 'patient',
      'isApproved': role != 'doctor',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));

    await _db.collection('patients').doc(user.uid).set({
      'fullName': name,
      'nic': '',
      'phone': phone,
      'email': user.email ?? email,
      'preferredLanguage': 'English',
      'profileImageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (isDoctor) {
      batch.set(_db.collection('doctors').doc(user.uid), {
        ...profile,
        'specialization': '',
        'roomNo': '',
      });
    } else {
      batch.set(_db.collection('patients').doc(user.uid), {
        ...profile,
        'history': <dynamic>[],
      });
    }

    // Keep only role and approval metadata here for login routing and the
    // existing doctor approval gate. Personal profile data lives separately.
    batch.set(_db.collection('users').doc(user.uid), {
      'role': role,
      'isVerified': !isDoctor,
      'isApproved': !isDoctor,
      'createdAt': now,
    });
    await batch.commit();
  }

  /// Load auth metadata and merge in the role-specific profile document.
  Future<UserModel?> getUserData(String uid) async {
    final results = await Future.wait([
      _db.collection('users').doc(uid).get(),
      _db.collection('patients').doc(uid).get(),
      _db.collection('doctors').doc(uid).get(),
    ]);
    final metadata = results[0].data();
    final patient = results[1].data();
    final doctor = results[2].data();
    if (metadata == null && patient == null && doctor == null) return null;

    final role = metadata?['role']?.toString() ??
        (doctor != null ? 'doctor' : 'patient');
    final profile = role == 'doctor' ? doctor : patient;
    final authUser = _auth.currentUser;
    final merged = <String, dynamic>{
      ...?metadata,
      ...?profile,
      'role': role,
      'email': profile?['email'] ?? metadata?['email'] ?? authUser?.email ?? '',
      'isVerified': metadata?['isVerified'] ?? profile?['isVerified'] ?? true,
      'isApproved': metadata?['isApproved'] ?? profile?['isApproved'] ?? role != 'doctor',
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
