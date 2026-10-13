import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/patient_service.dart';

class DepartmentStatusScreen extends StatefulWidget {
  const DepartmentStatusScreen({super.key});

  @override
  State<DepartmentStatusScreen> createState() =>
      _DepartmentStatusScreenState();
}

class _DepartmentStatusScreenState extends State<DepartmentStatusScreen> {
  final PatientService _service = PatientService();

  // ============================================================
  //  JOIN QUEUE DIALOG
  // ============================================================
  Future<void> _joinQueue() async {
    final patientNameCtrl = TextEditingController();
    String selectedDepartment = 'General Medicine';
    String selectedHospital = 'Colombo General Hospital';
    bool isLoading = false;

    final departments = [
      'General Medicine',
      'Dental Clinic',
      'Eye Clinic',
      'ENT Clinic',
      'Cardiology',
      'Pediatrics',
    ];

    final hospitals = [
      'Colombo General Hospital',
      'Sri Jayawardenepura General Hospital',
      'North Colombo Teaching Hospital',
      'National Hospital of Sri Lanka',
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Join OPD Queue',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Patient Name',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: patientNameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Kamal Perera',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Hospital',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedHospital,
                      isExpanded: true,
                      items: hospitals
                          .map((h) => DropdownMenuItem(
                                value: h,
                                child: Text(h),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(
                          () => selectedHospital = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Department',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDepartment,
                      isExpanded: true,
                      items: departments
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(
                          () => selectedDepartment = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (patientNameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please enter patient name')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        await _service.joinQueue(
                          patientName: patientNameCtrl.text.trim(),
                          department: selectedDepartment,
                          hospital: selectedHospital,
                        );

                        if (!mounted) return;
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('You joined the queue!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Join Queue',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  LEAVE QUEUE
  // ============================================================
  Future<void> _leaveQueue(String entryId, String tokenNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave Queue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to leave the queue?\n\n'
          'Your token $tokenNumber will be cancelled and you will '
          'lose your position.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Leave',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.leaveQueue(entryId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You left the queue'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Department Status',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF3B82F6)),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: _service.getMyActiveQueueEntry(),
          builder: (context, mySnapshot) {
            if (mySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final myEntry = mySnapshot.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (myEntry != null)
                    _myActiveQueueSection(myEntry)
                  else
                    _joinQueueBanner(),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Department Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('h:mm a').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined,
                            color: Color(0xFF3B82F6), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Privacy Mode: Wait metrics and load counts only.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1E40AF),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _service.getDepartmentQueues(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _errorState(snapshot.error.toString());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _emptyDepartmentsState();
                      }

                      return Column(
                        children: snapshot.data!.map((dept) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _departmentCard(dept),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index != 3) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ============================================================
  //  MY ACTIVE QUEUE SECTION
  // ============================================================
  Widget _myActiveQueueSection(Map<String, dynamic> entry) {
    final joinedAt = (entry['joinedAt'] as Timestamp).toDate();
    final department = entry['department'] as String? ?? '';
    final hospital = entry['hospital'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle,
                            color: Color(0xFF10B981), size: 8),
                        SizedBox(width: 6),
                        Text(
                          'YOU ARE IN QUEUE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry['tokenNumber'] ?? 'T-000',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                department,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_hospital,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hospital,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _statBox(
                      '${entry['patientsAhead'] ?? 0}',
                      'Patients Ahead',
                      Icons.people_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statBox(
                      '${entry['estimatedWait'] ?? 0}m',
                      'Est. Wait',
                      Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statBox(
                      DateFormat('h:mm a').format(joinedAt),
                      'Joined',
                      Icons.login,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _nowServingRow(department, hospital),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => _leaveQueue(
                      entry['id'], entry['tokenNumber']),
                  icon: const Icon(Icons.exit_to_app,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Leave Queue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.white54, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _queueProgressCard(entry),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nowServingRow(String department, String hospital) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _service.getNowServingToken(department, hospital),
      builder: (context, snapshot) {
        final nowServing = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOW SERVING',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nowServing != null
                          ? nowServing['tokenNumber'] ?? 'Waiting'
                          : 'Not started yet',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _queueProgressCard(Map<String, dynamic> entry) {
    final patientsAhead = entry['patientsAhead'] as int? ?? 0;
    final totalInQueue = patientsAhead + 1;
    final completed = totalInQueue > 0
        ? (totalInQueue - patientsAhead - 1) / totalInQueue
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline,
                  color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 8),
              Text(
                'Your Queue Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completed.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Started',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600)),
              Text(
                patientsAhead == 0
                    ? "You're next!"
                    : '$patientsAhead more to go',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const Text('Your Turn',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD966)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    patientsAhead == 0
                        ? 'Your turn is next! Please be ready.'
                        : 'Stay nearby. You will be notified when your turn is near.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _joinQueueBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDBEAFE), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF3B82F6),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Not in any queue',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join an OPD queue to get your token and track '
            'your live position.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _joinQueue,
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.white, size: 20),
              label: const Text(
                'Join OPD Queue',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _departmentCard(Map<String, dynamic> dept) {
    final statusColor = dept['statusColor'] as Color;
    final waiting = dept['waiting'] as int? ?? 0;
    final serving = dept['serving'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dept['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dept['status'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Queued: ',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                  Text(
                    '${dept['queued']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text('Avg Wait: ',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)),
              Text(
                '${dept['waitTime']} min',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (waiting > 0 || serving > 0) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),
            Row(
              children: [
                if (serving > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle,
                            color: Color(0xFF10B981), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$serving serving',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (waiting > 0) ...[
                  if (serving > 0) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top,
                            color: Color(0xFFD97706), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$waiting waiting',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyDepartmentsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No active queues',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No patients have joined any department queue yet today.',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline,
              size: 50, color: Colors.red.shade400),
          const SizedBox(height: 12),
          const Text(
            'Could not load queues',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}