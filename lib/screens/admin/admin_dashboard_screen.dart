import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'admin_user_list_screen.dart';
import 'admin_pending_doctors_screen.dart';

/// Main Admin Dashboard with summary cards and quick-access navigation.
class AdminDashboardScreen extends StatefulWidget {
  final UserModel admin;

  const AdminDashboardScreen({super.key, required this.admin});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  int _currentIndex = 0;

  // ─── Color palette ──────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0F172A);
  static const Color _primary = Color(0xFF1E40AF);
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _surface = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildOverviewPage(),
      AdminUserListScreen(role: 'patient', admin: widget.admin),
      AdminUserListScreen(role: 'doctor', admin: widget.admin),
      AdminPendingDoctorsScreen(admin: widget.admin),
    ];

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ────────────────────────────────────────────────────────
  // APP BAR
  // ────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final titles = ['Dashboard', 'Patients', 'Doctors', 'Pending Approvals'];
    return AppBar(
      backgroundColor: _primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titles[_currentIndex],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('OPD Connect Admin',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
            ],
          ),
        ],
      ),
      actions: [
        // Pending badge
        StreamBuilder<List<UserModel>>(
          stream: _adminService.getPendingDoctorsStream(),
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => setState(() => _currentIndex = 3),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$count',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            );
          },
        ),
        PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: _accent,
            child: Text(
              widget.admin.name.isNotEmpty ? widget.admin.name[0].toUpperCase() : 'A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') AuthService().signOut();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.admin.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(widget.admin.email.isNotEmpty ? widget.admin.email : widget.admin.emailOrPhone,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              ],
            )),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION
  // ────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primary,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_rounded), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions_rounded), label: 'Pending'),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // OVERVIEW PAGE — stat cards + recent activity
  // ────────────────────────────────────────────────────────
  Widget _buildOverviewPage() {
    return FutureBuilder<Map<String, int>>(
      future: _adminService.getDashboardStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final totalPatients = stats['totalPatients'] ?? 0;
        final totalDoctors = stats['totalDoctors'] ?? 0;
        final pendingDoctors = stats['pendingDoctors'] ?? 0;
        final totalUsers = stats['totalUsers'] ?? 0;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Greeting
              Text(
                'Welcome back,',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                widget.admin.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _primaryDark),
              ),
              const SizedBox(height: 24),

              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _StatCard(
                    title: 'Total Users',
                    value: '$totalUsers',
                    icon: Icons.group_rounded,
                    gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _StatCard(
                    title: 'Patients',
                    value: '$totalPatients',
                    icon: Icons.person_rounded,
                    gradient: const [Color(0xFF0D9488), Color(0xFF059669)],
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _StatCard(
                    title: 'Doctors',
                    value: '$totalDoctors',
                    icon: Icons.medical_services_rounded,
                    gradient: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  _StatCard(
                    title: 'Pending Approvals',
                    value: '$pendingDoctors',
                    icon: Icons.hourglass_top_rounded,
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Quick actions
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryDark)),
              const SizedBox(height: 14),
              _QuickActionTile(
                icon: Icons.person_add_alt_1_rounded,
                color: const Color(0xFF2563EB),
                title: 'Manage Patients',
                subtitle: 'View, edit or remove patient accounts',
                onTap: () => setState(() => _currentIndex = 1),
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: Icons.verified_user_rounded,
                color: const Color(0xFF7C3AED),
                title: 'Manage Doctors',
                subtitle: 'View, edit or remove doctor accounts',
                onTap: () => setState(() => _currentIndex = 2),
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Pending Doctor Approvals',
                subtitle: 'Review and approve new doctor registrations',
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REUSABLE STAT CARD
// ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top icon badge
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              // Value and title section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REUSABLE QUICK-ACTION TILE
// ─────────────────────────────────────────────────────────────
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
