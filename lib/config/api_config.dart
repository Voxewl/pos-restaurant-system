import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 1. Android Emulator needs 10.0.2.2 to reach PC host
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    // 2. Web / Tablet / Local PC devices connect to PC's LAN IP
    return 'http://192.168.1.116:3000/api';
  }

  static String get menuUrl => '$baseUrl/menu';
  static String get orderUrl => '$baseUrl/orders';
}