import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/patient_service.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  final String? appointmentId;
  final String doctorName;
  final String department;
  final String hospital;
  final String token;
  final String dateTime;
  final bool isReschedule;

  const RescheduleAppointmentScreen({
    super.key,
    this.appointmentId,
    required this.doctorName,
    required this.department,
    required this.hospital,
    required this.token,
    required this.dateTime,
    this.isReschedule = true,
  });

  @override
  State<RescheduleAppointmentScreen> createState() =>
      _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState
    extends State<RescheduleAppointmentScreen> {
  final PatientService _patientService = PatientService();
  bool _isSaving = false;
  // ===== FORM STATE =====
  late DateTime _selectedDate;
  late String _selectedSession;

  // ===== SESSIONS =====
  final List<String> _sessions = ['Morning', 'Afternoon', 'Evening'];

  final Map<String, IconData> _sessionIcons = {
    'Morning': Icons.wb_sunny_outlined,
    'Afternoon': Icons.wb_twilight,
    'Evening': Icons.nights_stay_outlined,
  };

  final Map<String, Color> _sessionColors = {
    'Morning': const Color(0xFFF59E0B),
    'Afternoon': const Color(0xFF3B82F6),
    'Evening': const Color(0xFF8B5CF6),
  };

  final Map<String, String> _sessionTimeRanges = {
    'Morning': '08:00 AM - 11:30 AM',
    'Afternoon': '12:00 PM - 03:00 PM',
    'Evening': '03:30 PM - 06:00 PM',
  };

  final Map<String, String> _sessionDescriptions = {
    'Morning': 'Early appointments starting at 8 AM',
    'Afternoon': 'Mid-day appointments starting at 12 PM',
    'Evening': 'Late appointments starting at 3:30 PM',
  };

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime.now();

    // Default session
    _selectedSession = 'Morning';

    // ===== Current appointment එකෙන් session එක guess කරන්න =====
    if (widget.dateTime.contains('AM')) {
      _selectedSession = 'Morning';
    } else if (widget.dateTime.contains('PM')) {
      // PM time එක බලලා Afternoon ද Evening ද කියලා තීරණය කරන්න
      final match = RegExp(r'(\d+):').firstMatch(widget.dateTime);
      if (match != null) {
        final hour = int.tryParse(match.group(1) ?? '') ?? 0;
        if (hour >= 12 && hour < 3) {
          _selectedSession = 'Afternoon';
        } else {
          _selectedSession = 'Evening';
        }
      } else {
        _selectedSession = 'Afternoon';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isReschedule ? 'Reschedule Appointment' : 'Modify Booking';
    final buttonText =
        widget.isReschedule ? 'Confirm Reschedule' : 'Save Changes';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== CURRENT APPOINTMENT CARD =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CURRENT APPOINTMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                            letterSpacing: 0.8,
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
                            widget.token,
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
                    Text(
                      widget.doctorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.department,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.hospital,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          widget.dateTime,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== FORM HEADER =====
              const Text(
                'Change Date & Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a new date and session for your appointment.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // ===== FIXED DETAILS CARD =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APPOINTMENT DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _readOnlyRow(
                      icon: Icons.local_hospital_outlined,
                      label: 'Hospital',
                      value: widget.hospital,
                    ),
                    const SizedBox(height: 12),
                    _readOnlyRow(
                      icon: Icons.medical_services_outlined,
                      label: 'Department',
                      value: widget.department,
                    ),
                    const SizedBox(height: 12),
                    _readOnlyRow(
                      icon: Icons.person_outline,
                      label: 'Doctor',
                      value: widget.doctorName,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== DATE PICKER =====
              _fieldLabel('Select New Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Color(0xFF3B82F6), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to change date',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ===== SESSION SELECTOR =====
              _fieldLabel('Select Session'),
              const SizedBox(height: 4),
              Text(
                'Choose one of the three available OPD sessions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 14),

              // ===== SESSION CARDS =====
              ..._sessions.map((session) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _sessionCard(session),
                );
              }).toList(),

              const SizedBox(height: 12),

              // ===== INFO CARD =====
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF3B82F6), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isReschedule
                            ? 'Rescheduling is free of charge. Your old slot will be released once you confirm.'
                            : 'Changes will be applied immediately. Please review carefully before saving.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== NEW SLOT SUMMARY =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEW APPOINTMENT SUMMARY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                    ),
                    _summaryRow(
                      Icons.wb_twilight,
                      'Session',
                      _selectedSession,
                    ),
                    _summaryRow(
                      Icons.access_time,
                      'Time Range',
                      _sessionTimeRanges[_selectedSession] ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== CONFIRM BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _showConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ===== CANCEL BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
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

  // ===== Session Card =====
  Widget _sessionCard(String session) {
    final isSelected = _selectedSession == session;
    final sessionColor = _sessionColors[session] ?? Colors.blue;
    final sessionIcon = _sessionIcons[session] ?? Icons.access_time;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSession = session;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? sessionColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? sessionColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: sessionColor.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.04),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? sessionColor
                    : sessionColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sessionIcon,
                color: isSelected ? Colors.white : sessionColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? sessionColor
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: isSelected
                            ? sessionColor
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sessionTimeRanges[session] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? sessionColor
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sessionDescriptions[session] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: sessionColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== Read-Only Row =====
  Widget _readOnlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, size: 10, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Fixed',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== CALENDAR PICKER =====
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Select New Appointment Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ===== Field Label =====
  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // ===== Summary Row =====
  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Confirmation Dialog =====
  void _showConfirmationDialog(BuildContext context) {
    final action = widget.isReschedule ? 'reschedule' : 'modify';
    final sessionColor = _sessionColors[_selectedSession] ?? Colors.blue;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.isReschedule ? 'Confirm Reschedule' : 'Confirm Changes',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to $action this appointment?',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _dialogRow('👨‍⚕️', widget.doctorName),
                  _dialogRow('🏥', widget.hospital),
                  const SizedBox(height: 10),
                  const Text(
                    'New Slot:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _dialogRow(
                    '📅',
                    DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                  ),
                  _dialogRow(
                    _sessionEmoji(_selectedSession),
                    _selectedSession,
                  ),
                  _dialogRow(
                    '🕐',
                    _sessionTimeRanges[_selectedSession] ?? '',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep it'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: sessionColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _isSaving
                ? null
                : () async {
              Navigator.pop(ctx);
              if (widget.appointmentId == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment ID is unavailable'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              setState(() => _isSaving = true);
              try {
                await _patientService.rescheduleAppointment(
                  appointmentId: widget.appointmentId!,
                  newDate: _selectedDate,
                  newSession: _sessionTimeRanges[_selectedSession] ??
                      _selectedSession,
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isReschedule
                          ? 'Appointment rescheduled'
                          : 'Appointment updated',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (error) {
                if (!mounted) return;
                setState(() => _isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not update appointment: $error'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Yes, Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Session Emoji =====
  String _sessionEmoji(String session) {
    switch (session) {
      case 'Morning':
        return '🌅';
      case 'Afternoon':
        return '☀️';
      case 'Evening':
        return '🌙';
      default:
        return '⏰';
    }
  }

  // ===== Dialog Row =====
  Widget _dialogRow(String emoji, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}