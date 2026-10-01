import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  // Use getters so Firebase isn't accessed before Firebase.initializeApp()
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Retrieve user profile and role from Firestore
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // Register Patient or Doctor
  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String name,
    required String role, // 'patient' or 'doctor'
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await _db.collection('users').doc(credential.user!.uid).set({
        'emailOrPhone': email,
        'name': name,
        'role': role,
        'isVerified': role == 'patient', // Doctors need IT approval (FR31)
      });
    }
    return credential;
  }

  // Login for All Roles (Patient, Doctor, Admin)
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}