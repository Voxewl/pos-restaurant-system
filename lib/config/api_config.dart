import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static String get menuUrl => '$baseUrl/menu';
  static String get orderUrl => '$baseUrl/orders';
}