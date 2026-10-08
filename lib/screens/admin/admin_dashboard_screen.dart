import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../staff/staff_workspace.dart';

/// The authenticated administrator entry point uses live Firebase records.
class AdminDashboardScreen extends StatelessWidget {
  final UserModel admin;
  const AdminDashboardScreen({super.key, required this.admin});
  @override
  Widget build(BuildContext context) => HospitalStaffWorkspace(
    actorId: admin.uid,
    actorName: admin.name,
    onSignOut: () => AuthService().signOut(),
  );
}
