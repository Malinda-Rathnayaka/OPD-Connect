import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/patient/patient_home_screen.dart';

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

            // ─── Doctor Approval Gate ──────────────────────
            // If the doctor account has NOT been approved by admin,
            // show a "pending approval" screen and block dashboard access.
            if (user.role == 'doctor' && !user.isApproved) {
              return _DoctorPendingApprovalScreen(authService: authService);
            }

            // ─── Legacy verified-flag gate (non-doctor) ───
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

            // ─── Role-based routing ───────────────────────
            switch (user.role) {
              case 'admin':
                return AdminDashboardScreen(admin: user);
              case 'doctor':
                return RoleHomeScreen(role: 'Doctor Dashboard (D-01)', user: user);
              case 'patient':
              default:
                return const PatientHomeScreen();
            }
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DOCTOR PENDING APPROVAL SCREEN
// ─────────────────────────────────────────────────────────────
// Shown when a doctor logs in but admin has not yet approved
// their account. The doctor is signed out and redirected to the
// login page with a clear message.
class _DoctorPendingApprovalScreen extends StatelessWidget {
  final AuthService authService;

  const _DoctorPendingApprovalScreen({required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated hourglass icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 56,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Account Pending Approval',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'Your doctor account has been registered successfully, '
                  'but the hospital admin has not approved your account yet.\n\n'
                  'Please wait until the admin reviews and approves your registration. '
                  'You will be able to access the Doctor Dashboard once approved.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFF3B82F6), size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Contact the hospital IT administrator if you believe this is taking too long.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Back to login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => authService.signOut(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PLACEHOLDER ROLE HOME SCREEN (patient / doctor)
// ─────────────────────────────────────────────────────────────
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