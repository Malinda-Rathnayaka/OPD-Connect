import 'package:flutter/material.dart';
import '../../utils/language_strings.dart';

class AlertsSettingsScreen extends StatefulWidget {
  const AlertsSettingsScreen({super.key});

  @override
  State<AlertsSettingsScreen> createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> {
  int _selectedTab = 0;
  bool _smsNotifications = true;
  bool _pushAlerts = false;
  int _selectedThreshold = 0;
  int _selectedLanguage = 0; // 0 = English, 1 = Sinhala, 2 = Tamil
  double _textSize = 1.0;

  // ===== භාෂාව අනුව strings =====
  String get _langCode {
    if (_selectedLanguage == 1) return 'si';
    if (_selectedLanguage == 2) return 'ta';
    return 'en';
  }

  Map<String, String> get _t => LanguageStrings.getMap(_langCode);

  // ===== Threshold labels — භාෂාව අනුව =====
  List<String> get _thresholds => [
        _t['threshold_3']!,
        _t['threshold_5']!,
        _t['threshold_10']!,
      ];

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
        title: Text(
          _t['app_title']!,
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
              // ===== TAB SWITCHER =====
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _tabButton(_t['tab_alerts']!, 0),
                    _tabButton(_t['tab_settings']!, 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_selectedTab == 1) ...[
                // ===== 1. NOTIFICATION CHANNELS =====
                _sectionCard(
                  title: _t['notification_channels']!,
                  children: [
                    _switchRow(
                      title: _t['sms_notifications']!,
                      subtitle: _t['sms_subtitle']!,
                      value: _smsNotifications,
                      onChanged: (val) =>
                          setState(() => _smsNotifications = val),
                    ),
                    const SizedBox(height: 8),
                    _switchRow(
                      title: _t['push_alerts']!,
                      subtitle: _t['push_subtitle']!,
                      value: _pushAlerts,
                      onChanged: (val) => setState(() => _pushAlerts = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== 2. QUEUE ALERT THRESHOLD =====
                _sectionCard(
                  title: _t['queue_threshold']!,
                  children: [
                    Row(
                      children: List.generate(_thresholds.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index < _thresholds.length - 1 ? 8 : 0,
                            ),
                            child: _pillButton(
                              label: _thresholds[index],
                              isSelected: _selectedThreshold == index,
                              onTap: () =>
                                  setState(() => _selectedThreshold = index),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== 3. PREFERRED LANGUAGE =====
                _sectionCard(
                  title: _t['preferred_language']!,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _pillButton(
                            label: 'English',
                            isSelected: _selectedLanguage == 0,
                            onTap: () =>
                                setState(() => _selectedLanguage = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _pillButton(
                            label: 'සිංහල',
                            isSelected: _selectedLanguage == 1,
                            onTap: () =>
                                setState(() => _selectedLanguage = 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _pillButton(
                            label: 'தமிழ்',
                            isSelected: _selectedLanguage == 2,
                            onTap: () =>
                                setState(() => _selectedLanguage = 2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== 4. APP TEXT SIZE =====
                _sectionCard(
                  title: _t['text_size']!,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _textSize,
                            min: 0.8,
                            max: 1.2,
                            divisions: 2,
                            activeColor: const Color(0xFF3B82F6),
                            inactiveColor: Colors.grey.shade300,
                            onChanged: (val) =>
                                setState(() => _textSize = val),
                          ),
                        ),
                        const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== SAVE BUTTON =====
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_t['settings_saved']!),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _t['save_changes']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                _emptyAlertsState(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index != 4) Navigator.pop(context);
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: _t['nav_home']!),
          BottomNavigationBarItem(
              icon: const Icon(Icons.search), label: _t['nav_search']!),
          BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today),
              label: _t['nav_appointments']!),
          BottomNavigationBarItem(
              icon: const Icon(Icons.people), label: _t['nav_queue']!),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: _t['nav_profile']!),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _pillButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyAlertsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_none,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _t['no_alerts']!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t['no_alerts_sub']!,
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
}