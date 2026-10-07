import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ⚠️ pubspec.yaml එකට intl package එක add කරන්න ඕන

class RescheduleAppointmentScreen extends StatefulWidget {
  final String doctorName;
  final String department;
  final String token;
  final String dateTime;
  final bool isReschedule;

  const RescheduleAppointmentScreen({
    super.key,
    required this.doctorName,
    required this.department,
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
  // ===== FORM STATE =====
  late String _selectedHospital;
  late String _selectedDepartment;
  late String _selectedDoctor;
  late DateTime _selectedDate; // DateTime විදියට
  late String _selectedTimeSlot;

  // ===== DROPDOWN DATA =====
  final List<String> _hospitals = [
    'Colombo General Hospital',
    'Sri Jayawardenepura General Hospital',
    'North Colombo Teaching Hospital',
    'National Hospital of Sri Lanka',
  ];

  final List<String> _departments = [
    'General Medicine',
    'Dental Clinic',
    'Eye Clinic',
    'ENT Clinic',
    'Cardiology',
    'Pediatrics',
  ];

  final Map<String, List<String>> _doctorsByDepartment = {
    'General Medicine': [
      'Dr. Kamal Perera',
      'Dr. Nishantha Silva',
      'Dr. Anura Wijesinghe',
    ],
    'Dental Clinic': [
      'Dr. Nishantha Silva',
      'Dr. Sithara Perera',
    ],
    'Eye Clinic': [
      'Dr. Anura Wijesinghe',
      'Dr. Mohamed Rizan',
    ],
    'ENT Clinic': [
      'Dr. Fatima Nafeesa',
      'Dr. Gayan Alwis',
    ],
    'Cardiology': [
      'Dr. Nimal Sirisena',
      'Dr. Ruwan Senanayake',
    ],
    'Pediatrics': [
      'Dr. Ayesha Fernando',
      'Dr. Nadisha Perera',
    ],
  };

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
  ];

  // Disabled slots (demo)
  final Set<String> _unavailableSlots = {'10:00 AM', '02:30 PM'};

  @override
  void initState() {
    super.initState();

    // ===== CURRENT APPOINTMENT DATA PARSE කරන්න =====
    // widget.dateTime එකෙන් date සහ time අයින් කරන්න
    // උදා: "Today, 10:30 AM" හෝ "Wed, 24 Sep • 2:00 PM"

    // 1. Default values — current appointment එකෙන්
    _selectedHospital = _hospitals[0]; // CGH

    // Department එක `widget.department` එකෙන් ගන්න
    // උදා: "General Medicine • CGH Room 4" → "General Medicine"
    String deptFromWidget = widget.department.split('•')[0].trim();
    _selectedDepartment = _departments.contains(deptFromWidget)
        ? deptFromWidget
        : _departments[0];

    // Doctor එක `widget.doctorName` එකෙන්
    _selectedDoctor = widget.doctorName;

    // 2. Date & Time parse කරන්න
    // Default වශයෙන් අද දවස
    _selectedDate = DateTime.now();

    // Time slot එක extract කරන්න
    // උදා: "Today, 10:30 AM" → "10:30 AM"
    String timeFromWidget = '09:00 AM';
    if (widget.dateTime.contains('AM') || widget.dateTime.contains('PM')) {
      final parts = widget.dateTime.split(RegExp(r'[•,]'));
      for (var part in parts) {
        final trimmed = part.trim();
        if (trimmed.contains('AM') || trimmed.contains('PM')) {
          timeFromWidget = trimmed;
          break;
        }
      }
    }
    _selectedTimeSlot = _timeSlots.contains(timeFromWidget)
        ? timeFromWidget
        : _timeSlots[0];
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
                    Text(
                      widget.department,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
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
                'Update Appointment Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Change any field below to update your booking',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // ===== 1. HOSPITAL DROPDOWN =====
              _fieldLabel('Hospital'),
              const SizedBox(height: 8),
              _dropdownField<String>(
                value: _selectedHospital,
                items: _hospitals,
                icon: Icons.local_hospital_outlined,
                onChanged: (value) {
                  setState(() {
                    _selectedHospital = value!;
                  });
                },
              ),
              const SizedBox(height: 18),

              // ===== 2. DEPARTMENT DROPDOWN =====
              _fieldLabel('Department'),
              const SizedBox(height: 8),
              _dropdownField<String>(
                value: _selectedDepartment,
                items: _departments,
                icon: Icons.medical_services_outlined,
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value!;
                    _selectedDoctor =
                        _doctorsByDepartment[_selectedDepartment]![0];
                  });
                },
              ),
              const SizedBox(height: 18),

              // ===== 3. DOCTOR DROPDOWN =====
              _fieldLabel('Doctor'),
              const SizedBox(height: 8),
              _dropdownField<String>(
                value: _selectedDoctor,
                items: _doctorsByDepartment[_selectedDepartment]!,
                icon: Icons.person_outline,
                onChanged: (value) {
                  setState(() {
                    _selectedDoctor = value!;
                  });
                },
              ),
              const SizedBox(height: 18),

              // ===== 4. DATE PICKER (Calendar) =====
              _fieldLabel('Select Date'),
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
              const SizedBox(height: 18),

              // ===== 5. TIME SLOT GRID =====
              _fieldLabel('Select Time Slot'),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  return _slotCard(index);
                },
              ),
              const SizedBox(height: 20),

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

              // ===== SUMMARY CARD =====
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
                      'NEW APPOINTMENT SUMMARY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow(Icons.local_hospital_outlined, 'Hospital',
                        _selectedHospital),
                    _summaryRow(Icons.medical_services_outlined, 'Department',
                        _selectedDepartment),
                    _summaryRow(Icons.person_outline, 'Doctor',
                        _selectedDoctor),
                    _summaryRow(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                    ),
                    _summaryRow(
                        Icons.access_time, 'Time', _selectedTimeSlot),
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

  // ===== CALENDAR PICKER =====
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // අද ඉඳන්
      lastDate: DateTime.now().add(const Duration(days: 90)), // මාස 3ක්
      helpText: 'Select Appointment Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6), // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Colors.black87, // Body text
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

  // ===== Dropdown Field =====
  Widget _dropdownField<T>({
    required T value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.toString())),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ===== Slot Card =====
  Widget _slotCard(int index) {
    final slot = _timeSlots[index];
    final isAvailable = !_unavailableSlots.contains(slot);
    final isSelected = _selectedTimeSlot == slot && isAvailable;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                _selectedTimeSlot = slot;
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: !isAvailable
              ? Colors.grey.shade100
              : (isSelected ? const Color(0xFF3B82F6) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !isAvailable
                ? Colors.grey.shade200
                : (isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            slot,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: !isAvailable
                  ? Colors.grey.shade400
                  : (isSelected ? Colors.white : Colors.black87),
              decoration:
                  !isAvailable ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
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
            width: 80,
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    'New Details:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _dialogRow('🏥', _selectedHospital),
                  _dialogRow('🩺', _selectedDepartment),
                  _dialogRow('👨‍⚕️', _selectedDoctor),
                  _dialogRow(
                    '📅',
                    DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                  ),
                  _dialogRow('🕐', _selectedTimeSlot),
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
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.isReschedule
                        ? 'Appointment rescheduled successfully'
                        : 'Appointment updated successfully',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );

              // TODO: Firebase එකෙන් booking එක update කරන්න
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