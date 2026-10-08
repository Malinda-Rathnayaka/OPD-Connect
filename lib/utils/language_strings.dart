// ===== හැම භාෂාවකටම වචන මෙතන =====

class LanguageStrings {
  // ===== ENGLISH =====
  static const Map<String, String> english = {
    'app_title': 'Alerts & Settings',
    'tab_alerts': 'Alerts',
    'tab_settings': 'Settings',
    'notification_channels': 'Notification Channels',
    'sms_notifications': 'SMS Notifications',
    'sms_subtitle': 'Receive status alerts via text message',
    'push_alerts': 'Push Alerts',
    'push_subtitle': 'Get notified when your turn is near',
    'queue_threshold': 'Queue Alert Threshold',
    'threshold_3': '3 Patients',
    'threshold_5': '5 Patients',
    'threshold_10': '10 Patients',
    'preferred_language': 'Preferred Language',
    'lang_english': 'English',
    'lang_sinhala': 'Sinhala',
    'lang_tamil': 'Tamil',
    'text_size': 'App Text Size',
    'save_changes': 'Save Changes',
    'no_alerts': 'No new alerts',
    'no_alerts_sub': 'You will see queue and appointment alerts here',
    'settings_saved': 'Settings saved successfully',
    // Bottom nav
    'nav_home': 'Home',
    'nav_search': 'Search',
    'nav_appointments': 'Appointments',
    'nav_queue': 'Queue',
    'nav_profile': 'Profile',
  };

  // ===== SINHALA =====
  static const Map<String, String> sinhala = {
    'app_title': 'දැනුම්දීම් සහ සැකසුම්',
    'tab_alerts': 'දැනුම්දීම්',
    'tab_settings': 'සැකසුම්',
    'notification_channels': 'දැනුම්දීම් මාර්ග',
    'sms_notifications': 'SMS දැනුම්දීම්',
    'sms_subtitle': 'කෙටි පණිවිඩ මගින් තත්ත්ව දැනුම්දීම් ලබා ගන්න',
    'push_alerts': 'Push දැනුම්දීම්',
    'push_subtitle': 'ඔබේ වාරය ළඟා වන විට දැනුම්දීම් ලබා ගන්න',
    'queue_threshold': 'පෝලිම් දැනුම්දීම් සීමාව',
    'threshold_3': 'රෝගීන් 3',
    'threshold_5': 'රෝගීන් 5',
    'threshold_10': 'රෝගීන් 10',
    'preferred_language': 'කැමති භාෂාව',
    'lang_english': 'English',
    'lang_sinhala': 'සිංහල',
    'lang_tamil': 'දෙමළ',
    'text_size': 'යෙදුම් අකුරු ප්‍රමාණය',
    'save_changes': 'වෙනස්කම් සුරකින්න',
    'no_alerts': 'නව දැනුම්දීම් නොමැත',
    'no_alerts_sub': 'පෝලිම් සහ වෙන් කිරීම් දැනුම්දීම් මෙහි දිස්වනු ඇත',
    'settings_saved': 'සැකසුම් සාර්ථකව සුරකින ලදී',
    'nav_home': 'මුල් පිටුව',
    'nav_search': 'සොයන්න',
    'nav_appointments': 'වෙන් කිරීම්',
    'nav_queue': 'පෝලිම',
    'nav_profile': 'පැතිකඩ',
  };

  // ===== TAMIL =====
  static const Map<String, String> tamil = {
    'app_title': 'விழிப்பூட்டல்கள் & அமைப்புகள்',
    'tab_alerts': 'விழிப்பூட்டல்கள்',
    'tab_settings': 'அமைப்புகள்',
    'notification_channels': 'அறிவிப்பு சேனல்கள்',
    'sms_notifications': 'SMS அறிவிப்புகள்',
    'sms_subtitle': 'குறுஞ்செய்தி மூலம் தகவல் விழிப்பூட்டல்கள் பெறுங்கள்',
    'push_alerts': 'Push விழிப்பூட்டல்கள்',
    'push_subtitle': 'உங்கள் வரிசை நெருங்கும்போது அறிவிப்புகள் பெறுங்கள்',
    'queue_threshold': 'வரிசை விழிப்பூட்டல் வரம்பு',
    'threshold_3': '3 நோயாளிகள்',
    'threshold_5': '5 நோயாளிகள்',
    'threshold_10': '10 நோயாளிகள்',
    'preferred_language': 'விருப்பமான மொழி',
    'lang_english': 'English',
    'lang_sinhala': 'සිංහල',
    'lang_tamil': 'தமிழ்',
    'text_size': 'எழுத்து அளவு',
    'save_changes': 'மாற்றங்களை சேமிக்கவும்',
    'no_alerts': 'புதிய விழிப்பூட்டல்கள் இல்லை',
    'no_alerts_sub': 'வரிசை மற்றும் சந்திப்பு விழிப்பூட்டல்கள் இங்கே தோன்றும்',
    'settings_saved': 'அமைப்புகள் வெற்றிகரமாக சேமிக்கப்பட்டன',
    'nav_home': 'முகப்பு',
    'nav_search': 'தேடல்',
    'nav_appointments': 'சந்திப்புகள்',
    'nav_queue': 'வரிசை',
    'nav_profile': 'சுயவிவரம்',
  };

  // ===== Helper — භාෂාව අනුව map එක ගන්න =====
  static Map<String, String> getMap(String languageCode) {
    switch (languageCode) {
      case 'si':
        return sinhala;
      case 'ta':
        return tamil;
      case 'en':
      default:
        return english;
    }
  }
}