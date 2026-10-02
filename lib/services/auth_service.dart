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
    User? currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.email?.toLowerCase() != normalizedEmail) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        currentUser = credential.user;
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;

        final credential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        currentUser = credential.user;
      }
    }

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

    await _db.collection('users').doc(user.uid).set({
        'email': user.email ?? email,
        'phone': phone,
        'name': name,
        'role': role,
        'isVerified': role == 'patient', // Doctors require IT verification
        'isApproved': role != 'doctor', // Doctors need admin approval before login
        'createdAt': FieldValue.serverTimestamp(),
      });
  }

  /// Retrieve User Profile from Firestore
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
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