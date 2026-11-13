import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 1. Android Emulator
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    // 2. Windows Desktop App (always on the same PC as the server)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:3000/api';
    }
    // 3. Web / Tablet / Mobile devices on Wi-Fi
    return 'http://192.168.1.234:3000/api';
  }

  static String get menuUrl => '$baseUrl/menu';
  static String get orderUrl => '$baseUrl/orders';
}