import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/patient_service.dart';

class LiveQueueTrackerScreen extends StatefulWidget {
  final String? appointmentId; // ← අලුතින් add කරපු parameter එක

  const LiveQueueTrackerScreen({
    super.key,
    this.appointmentId, // optional — null නම් queue status විතරයි පෙන්නනවා
  });

  @override
  State<LiveQueueTrackerScreen> createState() =>
      _LiveQueueTrackerScreenState();
}

class _LiveQueueTrackerScreenState extends State<LiveQueueTrackerScreen>
{
  final PatientService _service = PatientService();

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
          'Live Queue Tracker',
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
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: _service.getMyActiveQueueEntry(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _errorState(snapshot.error.toString());
            }

            final myEntry = snapshot.data;

            if (myEntry == null) {
              return _notInQueueState();
            }

            return _queueContent(myEntry);
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
  //  NOT IN QUEUE STATE
  // ============================================================
  Widget _notInQueueState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: Color(0xFF3B82F6),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Not in any queue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are not currently in any queue. '
                'Join the queue from the Department Status page.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  ERROR STATE
  // ============================================================
  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 50, color: Colors.red.shade400),
              const SizedBox(height: 12),
              const Text(
                'Could not load queue',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  // ============================================================
  //  QUEUE CONTENT
  // ============================================================
  Widget _queueContent(Map<String, dynamic> entry) {
    final tokenNumber = entry['tokenNumber'] ?? 'T-000';
    final patientsAhead = (entry['patientsAhead'] ?? 0) as int;
    final estimatedWait = (entry['estimatedWait'] ?? 0) as int;
    final department = entry['department'] ?? '';
    final hospital = entry['hospital'] ?? '';

    final joinedAt = entry['joinedAt'] != null
        ? (entry['joinedAt'] as Timestamp).toDate()
        : DateTime.now();

    // Progress: 0% when just joined, 100% when it's your turn
    final totalInQueue = patientsAhead + 1;
    final progressValue = patientsAhead == 0
        ? 1.0
        : (totalInQueue - patientsAhead) / totalInQueue;

    // Departure advisor — 5 mins per patient ahead
    final departureTime = DateFormat('h:mm a').format(
      DateTime.now().add(Duration(minutes: estimatedWait)),
    );
    final waitTimeText = estimatedWait <= 0
        ? 'Now'
        : '$estimatedWait mins';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // ===== CIRCULAR PROGRESS WITH TOKEN =====
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progressValue),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: value,
                      backgroundColor: Colors.grey.shade200,
                      progressColor: const Color(0xFF3B82F6),
                      strokeWidth: 16,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'YOUR TOKEN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tokenNumber,
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: patientsAhead == 0
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              patientsAhead == 0
                                  ? "You're next!"
                                  : '$patientsAhead Patients Ahead',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: patientsAhead == 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30),

          // ===== DEPARTURE ADVISOR CARD =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD966)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Departure Advisor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  department,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hospital,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Based on current flow, you should arrive at the hospital by ',
                      ),
                      TextSpan(
                        text: departureTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Est. Wait Time:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      waitTimeText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== QUEUE STEPS =====
          _queueStep(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF3B82F6),
            title: 'Queued & Waiting',
            subtitle:
                'Token registered at ${DateFormat('h:mm a').format(joinedAt)}',
            isActive: true,
            isFilled: true,
          ),
          _queueStep(
            icon: Icons.radio_button_checked,
            iconColor: const Color(0xFFF59E0B),
            title: '$patientsAhead Patients Ahead',
            subtitle: patientsAhead == 0
                ? 'You are next in line'
                : 'Approx. $estimatedWait mins wait remaining',
            isActive: true,
            isFilled: true,
          ),
          _queueStep(
            icon: Icons.radio_button_unchecked,
            iconColor: patientsAhead == 0
                ? const Color(0xFF10B981)
                : Colors.grey,
            title: 'You are Next',
            subtitle: 'Prepare to head to the counter',
            isActive: patientsAhead == 0,
            isFilled: false,
          ),
          _queueStep(
            icon: Icons.radio_button_unchecked,
            iconColor: Colors.grey,
            title: 'Being Served',
            subtitle: 'Consultation in progress',
            isActive: false,
            isFilled: false,
            isLast: true,
          ),

          const SizedBox(height: 16),
          Text(
            'Last updated: Just now (${DateFormat('h:mm a').format(DateTime.now())})',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // ===== LEAVE QUEUE BUTTON =====
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _leaveQueue(entry['id'], tokenNumber),
              icon: const Icon(Icons.exit_to_app,
                  color: Color(0xFFEF4444), size: 20),
              label: const Text(
                'Leave Queue',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===== Queue Step Widget =====
  Widget _queueStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isFilled,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color:
                    isFilled ? const Color(0xFF3B82F6) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== Leave Queue =====
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
          ),
        );
        Navigator.pop(context);
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
}

// ─────────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR CIRCULAR PROGRESS
// ─────────────────────────────────────────────────────────────
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}