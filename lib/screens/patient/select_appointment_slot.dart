import 'package:flutter/material.dart';
import 'patient_home_screen.dart';
import 'find_opd_hospital.dart';
import 'doctor_availability.dart';
import 'my_family_profile.dart';
import 'review_confirm_booking.dart';

class SelectAppointmentSlotScreen extends StatefulWidget {
  const SelectAppointmentSlotScreen({super.key});

  @override
  State<SelectAppointmentSlotScreen> createState() => _SelectAppointmentSlotScreenState();
}

class _SelectAppointmentSlotScreenState extends State<SelectAppointmentSlotScreen> {
  final List<String> _dateLabels = const [
    'Mon\n22',
    'Tue\n23',
    'Wed\n24',
    'Thu\n25',
    'Fri\n26',
    'Sat\n27',
    'Sun\n28',
  ];

  final List<_AppointmentSlot> _slots = const [
    _AppointmentSlot(time: '9:00 AM', slotNumber: '#14'),
    _AppointmentSlot(time: '9:15 AM', slotNumber: '#15'),
    _AppointmentSlot(time: '9:30 AM', slotNumber: '#16'),
    _AppointmentSlot(time: '9:45 AM', slotNumber: '#17'),
    _AppointmentSlot(time: '10:00 AM', slotNumber: '#18'),
    _AppointmentSlot(time: '10:15 AM', slotNumber: '#19'),
  ];

  int _selectedDateIndex = 0;
  bool _morningSessionSelected = true;
  int _selectedSlotIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedSlot = _slots[_selectedSlotIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Select Appointment Slot'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dateLabels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDateIndex;
                  final dayParts = _dateLabels[index].split('\n');

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                      });
                    },
                    child: Container(
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayParts[0],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayParts[1],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SessionToggleButton(
                    label: 'Morning Session',
                    selected: _morningSessionSelected,
                    onTap: () {
                      setState(() {
                        _morningSessionSelected = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SessionToggleButton(
                    label: 'Evening Session',
                    selected: !_morningSessionSelected,
                    onTap: () {
                      setState(() {
                        _morningSessionSelected = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Selected Date: Monday, 22 Sep',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _slots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final slot = _slots[index];
                final isSelected = index == _selectedSlotIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSlotIndex = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.time,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slot.slotNumber,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Slot Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Mon 22 Sep • Slot ${selectedSlot.slotNumber}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dr. Perera • ${selectedSlot.time}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReviewConfirmBookingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientHomeScreen(),
                ),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindOpdHospitalScreen(),
                ),
              );
              break;
            case 2:
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyFamilyProfileScreen(),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorAvailabilityScreen(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_outlined),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SessionToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SessionToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.blue : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.blue,
          side: BorderSide(color: selected ? Colors.blue : Colors.blue.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AppointmentSlot {
  final String time;
  final String slotNumber;

  const _AppointmentSlot({
    required this.time,
    required this.slotNumber,
  });
}
