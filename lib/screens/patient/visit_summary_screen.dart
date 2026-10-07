import 'package:flutter/material.dart';
import 'reschedule_appointment_screen.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class VisitSummaryScreen extends StatelessWidget {
  final String doctorName;
  final String department;
  final String token;
  final String dateTime;

  const VisitSummaryScreen({
    super.key,
    required this.doctorName,
    required this.department,
    required this.token,
    required this.dateTime,
  });

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
          'Visit Summary',
          style: TextStyle(
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
              // ===== VISIT HEADER CARD =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'COMPLETED VISIT',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            token,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      department,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          dateTime,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===== DIAGNOSIS CARD =====
              _sectionCard(
                icon: Icons.medical_information_outlined,
                iconColor: Colors.red,
                title: 'Diagnosis',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Acute Pharyngitis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Patient reported mild throat irritation and difficulty swallowing. No known drug allergies.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ===== PRESCRIPTION CARD =====
              _sectionCard(
                icon: Icons.medication_outlined,
                iconColor: Colors.green,
                title: 'Prescription',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _medicationRow('Amoxicillin', '500mg • 3 times daily', '7 days'),
                    const Divider(height: 20),
                    _medicationRow('Paracetamol', '500mg • as needed', '3 days'),
                    const Divider(height: 20),
                    _medicationRow('Benzydamine gargle', '15ml • 3 times daily', '5 days'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ===== DOCTOR'S NOTES CARD =====
              _sectionCard(
                icon: Icons.note_alt_outlined,
                iconColor: Colors.blue,
                title: "Doctor's Notes",
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '"Rest well and stay hydrated. Avoid cold beverages for the next 5 days. '
                    'If symptoms persist beyond 3 days, please return for a follow-up."',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E40AF),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ===== FOLLOW-UP CARD =====
              _sectionCard(
                icon: Icons.event_repeat_outlined,
                iconColor: Colors.orange,
                title: 'Follow-up',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended in 2 weeks',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'If symptoms do not improve',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== BOOK AGAIN BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RescheduleAppointmentScreen(
                          doctorName: doctorName,
                          department: department,
                          token: 'New',
                          dateTime: 'Not scheduled',
                          isReschedule: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  label: const Text(
                    'Book This Doctor Again',
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
              const SizedBox(height: 12),

              // ===== DOWNLOAD PDF BUTTON =====
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // PDF generate කරන්න
                    final pdfBytes = await _generatePdf();

                    // PDF share / save කරන්න
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename:
                          'visit_summary_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                    );
                  },
                  icon: const Icon(Icons.download_outlined,
                      color: Colors.black87, size: 20),
                  label: const Text(
                    'Download Summary (PDF)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
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

  // ===== PDF GENERATE කරන FUNCTION එක =====
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    const primaryBlue = PdfColor.fromInt(0xFF3B82F6);
    const lightBlue = PdfColor.fromInt(0xFFEFF6FF);
    const lightOrange = PdfColor.fromInt(0xFFFFF3CD);
    const greyText = PdfColor.fromInt(0xFF6B7280);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ===== HEADER =====
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryBlue,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          'COMPLETED VISIT',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryBlue,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          token,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    doctorName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    department,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Date: ',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        dateTime,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ===== DIAGNOSIS =====
            _pdfSection(
              title: 'Diagnosis',
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Acute Pharyngitis',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Patient reported mild throat irritation and difficulty swallowing. No known drug allergies.',
                    style: pw.TextStyle(fontSize: 10, color: greyText),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ===== PRESCRIPTION =====
            _pdfSection(
              title: 'Prescription',
              child: pw.Column(
                children: [
                  _pdfMedicationRow(
                      'Amoxicillin', '500mg • 3 times daily', '7 days'),
                  pw.Divider(height: 12),
                  _pdfMedicationRow(
                      'Paracetamol', '500mg • as needed', '3 days'),
                  pw.Divider(height: 12),
                  _pdfMedicationRow('Benzydamine gargle',
                      '15ml • 3 times daily', '5 days'),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ===== DOCTOR'S NOTES =====
            _pdfSection(
              title: "Doctor's Notes",
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightBlue,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  '"Rest well and stay hydrated. Avoid cold beverages for the next 5 days. '
                  'If symptoms persist beyond 3 days, please return for a follow-up."',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: primaryBlue,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // ===== FOLLOW-UP =====
            _pdfSection(
              title: 'Follow-up',
              child: pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: lightOrange,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'Recommended in 2 weeks',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ===== FOOTER =====
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Generated by OPD Connect on ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: greyText,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'This is a computer-generated document. No signature required.',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: greyText,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ===== PDF Section Helper =====
  pw.Widget _pdfSection({
    required String title,
    required pw.Widget child,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1E40AF),
            ),
          ),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ===== PDF Medication Row =====
  pw.Widget _pdfMedicationRow(
      String name, String dosage, String duration) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              name,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              dosage,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromInt(0xFF6B7280),
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFDBEAFE),
            borderRadius: pw.BorderRadius.circular(20),
          ),
          child: pw.Text(
            duration,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1E40AF),
            ),
          ),
        ),
      ],
    );
  }

  // ===== Section Card Helper =====
  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ===== Medication Row =====
  Widget _medicationRow(String name, String dosage, String duration) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.medication,
            color: Color(0xFF10B981),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dosage,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            duration,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
        ),
      ],
    );
  }
}