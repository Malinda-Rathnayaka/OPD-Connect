import 'package:flutter/material.dart';

class DepartmentStatusScreen extends StatefulWidget {
  const DepartmentStatusScreen({super.key});

  @override
  State<DepartmentStatusScreen> createState() =>
      _DepartmentStatusScreenState();
}

class _DepartmentStatusScreenState extends State<DepartmentStatusScreen> {
  // ===== DEPARTMENTS DATA (Read + Create + Update + Delete) =====
  final List<Map<String, dynamic>> _departments = [
    {
      'id': '1',
      'name': 'General Medicine',
      'queued': 24,
      'waitTime': 12,
      'status': 'LOW',
    },
    {
      'id': '2',
      'name': 'Dental Clinic',
      'queued': 18,
      'waitTime': 35,
      'status': 'MODERATE',
    },
    {
      'id': '3',
      'name': 'Eye Clinic',
      'queued': 45,
      'waitTime': 52,
      'status': 'BUSY',
    },
    {
      'id': '4',
      'name': 'Pediatrics',
      'queued': 14,
      'waitTime': 18,
      'status': 'LOW',
    },
    {
      'id': '5',
      'name': 'Cardiology Unit',
      'queued': 32,
      'waitTime': 40,
      'status': 'MODERATE',
    },
  ];

  // ===== Status එකට අදාල වර්ණය =====
  Color _getStatusColor(String status) {
    switch (status) {
      case 'BUSY':
        return const Color(0xFFEF4444); // රතු
      case 'MODERATE':
        return const Color(0xFFF59E0B); // කහ
      case 'LOW':
      default:
        return const Color(0xFF3B82F6); // නිල්
    }
  }

  // ============================================================
  //  CRUD OPERATIONS
  // ============================================================

  // ===== CREATE — අලුත් department එකක් =====
  Future<void> _addDepartment() async {
    final result = await _showDepartmentForm(
      title: 'Add Department',
      buttonText: 'Add',
    );

    if (result != null) {
      setState(() {
        _departments.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': result['name'],
          'queued': result['queued'],
          'waitTime': result['waitTime'],
          'status': result['status'],
        });
      });

      _showSnackBar('Department added successfully', const Color(0xFF10B981));
    }
  }

  // ===== UPDATE — දැනට තියෙන department එකක් =====
  Future<void> _editDepartment(int index) async {
    final dept = _departments[index];

    final result = await _showDepartmentForm(
      title: 'Edit Department',
      buttonText: 'Update',
      initialName: dept['name'],
      initialQueued: dept['queued'].toString(),
      initialWaitTime: dept['waitTime'].toString(),
      initialStatus: dept['status'],
    );

    if (result != null) {
      setState(() {
        _departments[index] = {
          'id': dept['id'],
          'name': result['name'],
          'queued': result['queued'],
          'waitTime': result['waitTime'],
          'status': result['status'],
        };
      });

      _showSnackBar('Department updated successfully', const Color(0xFF3B82F6));
    }
  }

  // ===== DELETE — department එකක් අයින් කරන්න =====
  Future<void> _deleteDepartment(int index) async {
    final dept = _departments[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Department',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${dept['name']}"?\n\n'
          'This action cannot be undone.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
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
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _departments.removeAt(index);
      });

      _showSnackBar('Department deleted', const Color(0xFFEF4444));
    }
  }

  // ===== FORM DIALOG — Create + Update දෙකටම =====
  Future<Map<String, dynamic>?> _showDepartmentForm({
    required String title,
    required String buttonText,
    String? initialName,
    String? initialQueued,
    String? initialWaitTime,
    String? initialStatus,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final queuedController = TextEditingController(text: initialQueued ?? '');
    final waitTimeController =
        TextEditingController(text: initialWaitTime ?? '');
    String status = initialStatus ?? 'LOW';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Department Name =====
                  const Text(
                    'Department Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Eye Clinic',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ===== Queued Patients =====
                  const Text(
                    'Queued Patients',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: queuedController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 24',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ===== Average Wait Time =====
                  const Text(
                    'Average Wait Time (mins)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: waitTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 12',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ===== Status =====
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['LOW', 'MODERATE', 'BUSY'].map((s) {
                      final isSelected = status == s;
                      final color = _getStatusColor(s);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: s != 'BUSY' ? 6 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => status = s);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  // ===== Validation =====
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a department name'),
                      ),
                    );
                    return;
                  }

                  final queued = int.tryParse(queuedController.text.trim());
                  final waitTime =
                      int.tryParse(waitTimeController.text.trim());

                  if (queued == null || waitTime == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid numbers'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx, {
                    'name': nameController.text.trim(),
                    'queued': queued,
                    'waitTime': waitTime,
                    'status': status,
                  });
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===== Snackbar Helper =====
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  //  BUILD
  // ============================================================
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
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF3B82F6)),
            onPressed: _addDepartment,
            tooltip: 'Add Department',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER ROW =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Counter Updates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Updated just now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ===== PRIVACY MODE BANNER =====
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
                    const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E40AF),
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Privacy Mode Active: ',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  'Showing wait metrics and load counts only. Individual names hidden.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===== ADD DEPARTMENT BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addDepartment,
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text(
                    'Add New Department',
                    style: TextStyle(
                      fontSize: 14,
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
              const SizedBox(height: 16),

              // ===== EMPTY STATE =====
              if (_departments.isEmpty) _emptyState(),

              // ===== DEPARTMENT CARDS =====
              ..._departments.asMap().entries.map((entry) {
                final index = entry.key;
                final dept = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _departmentCard(dept, index),
                );
              }).toList(),

              const SizedBox(height: 10),
            ],
          ),
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

  // ===== Empty State =====
  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.local_hospital_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No departments yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add New Department" to get started',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== Department Card =====
  Widget _departmentCard(Map<String, dynamic> dept, int index) {
    final statusColor = _getStatusColor(dept['status']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Department name + Status badge =====
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
                  color: statusColor.withOpacity(0.15),
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

          // ===== Queued + Wait Time =====
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
                  Text(
                    'Queued: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${dept['queued']} Patients',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Avg Wait: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${dept['waitTime']} mins',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ===== Divider =====
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // ===== EDIT + DELETE buttons =====
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editDepartment(index),
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: Color(0xFF3B82F6)),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteDepartment(index),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}