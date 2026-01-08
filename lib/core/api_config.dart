import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 10.0.2.2 for Android emulator to access host's localhost
  // Use localhost for iOS simulator or Web
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    
    // For iOS and others
    return 'http://localhost:3000/api';
  }
}
