import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'admin_user_list_screen.dart';
import 'admin_pending_doctors_screen.dart';
import 'admin_leave_approvals_screen.dart';

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

  // ─── Color palette (refined for real-world feel) ────────
  static const Color _primaryDark = Color(0xFF0B1220);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _surface = Color(0xFFF5F7FB);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildOverviewPage(),
      AdminUserListScreen(role: 'patient', admin: widget.admin),
      AdminUserListScreen(role: 'doctor', admin: widget.admin),
      AdminPendingDoctorsScreen(admin: widget.admin),
      const AdminLeaveApprovalsScreen(),
    ];

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ────────────────────────────────────────────────────────
  // APP BAR — clean, modern, with soft shadow
  // ────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final titles = [
      'Dashboard',
      'Patients',
      'Doctors',
      'Pending Approvals',
      'Leave Approvals',
    ];
    return AppBar(
      backgroundColor: _primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titles[_currentIndex],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'OPD Connect Admin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.55),
                  letterSpacing: 0.2,
                ),
              ),
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
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 24),
                  onPressed: () => setState(() => _currentIndex = 3),
                  tooltip: 'Notifications',
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _primaryDark, width: 1.5),
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          color: Colors.white,
          elevation: 8,
          icon: Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: _accent,
              child: Text(
                widget.admin.name.isNotEmpty
                    ? widget.admin.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') AuthService().signOut();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              height: 68,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _accent.withOpacity(0.12),
                    child: Text(
                      widget.admin.name.isNotEmpty
                          ? widget.admin.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.admin.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.admin.email.isNotEmpty
                              ? widget.admin.email
                              : widget.admin.emailOrPhone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'logout',
              height: 44,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION — floating, rounded, elevated
  // ────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _primary,
          unselectedItemColor: _textSecondary.withOpacity(0.7),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 11.5,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.grid_view_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.grid_view_rounded, size: 24),
              ),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.people_alt_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.people_alt_rounded, size: 24),
              ),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.medical_services_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.medical_services_rounded, size: 24),
              ),
              label: 'Doctors',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.pending_actions_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.pending_actions_rounded, size: 24),
              ),
              label: 'Pending',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.event_available_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.event_available_rounded, size: 24),
              ),
              label: 'Leaves',
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // OVERVIEW PAGE — stat cards + quick actions
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
          color: _primary,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () async => setState(() {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              // ── Greeting header ──────────────────────────
              _buildGreetingHeader(),
              const SizedBox(height: 22),

              // ── Stats grid ───────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.08,
                children: [
                  _StatCard(
                    title: 'Total Users',
                    value: '$totalUsers',
                    icon: Icons.groups_rounded,
                    gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _StatCard(
                    title: 'Patients',
                    value: '$totalPatients',
                    icon: Icons.person_rounded,
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _StatCard(
                    title: 'Doctors',
                    value: '$totalDoctors',
                    icon: Icons.medical_services_rounded,
                    gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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

              // ── Quick actions header ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Quick action tiles ───────────────────────
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
                badge: pendingDoctors > 0 ? '$pendingDoctors' : null,
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: Icons.event_available_rounded,
                color: const Color(0xFF7C3AED),
                title: 'Doctor Leave Approvals',
                subtitle: 'Review and approve doctor leave requests',
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────
  // GREETING HEADER — avatar + welcome text
  // ────────────────────────────────────────────────────────
  Widget _buildGreetingHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withOpacity(0.15),
              child: Text(
                widget.admin.name.isNotEmpty
                    ? widget.admin.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.admin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REUSABLE STAT CARD — premium gradient card with soft shadow
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.08),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circle accent
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: -10,
                bottom: -30,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top icon badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    // Value and title
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
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.05,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REUSABLE QUICK-ACTION TILE — clean card with optional badge
// ─────────────────────────────────────────────────────────────
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: color.withOpacity(0.06),
        highlightColor: color.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container with soft tinted bg
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}