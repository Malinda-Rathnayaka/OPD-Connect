import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        return FutureBuilder<UserModel?>(
          future: authService.getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return const LoginScreen();
            }

            UserModel user = userSnapshot.data!;

            if (!user.isVerified) {
              return Scaffold(
                appBar: AppBar(title: const Text('Pending Verification')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Doctor account pending IT verification (FR31).'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => authService.signOut(),
                        child: const Text('Sign Out'),
                      )
                    ],
                  ),
                ),
              );
            }

            switch (user.role) {
              case 'admin':
                return RoleHomeScreen(role: 'IT Admin Dashboard (A-01)', user: user);
              case 'doctor':
                return RoleHomeScreen(role: 'Doctor Dashboard (D-01)', user: user);
              case 'patient':
              default:
                return RoleHomeScreen(role: 'Patient Home (P-01)', user: user);
            }
          },
        );
      },
    );
  }
}

class RoleHomeScreen extends StatelessWidget {
  final String role;
  final UserModel user;

  const RoleHomeScreen({super.key, required this.role, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          )
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${user.name}!\nRole: ${user.role.toUpperCase()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}