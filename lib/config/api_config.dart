import 'package:flutter/foundation.dart';

class ApiConfig {
  // For Android Emulator: use 10.0.2.2 to access host machine's localhost
  // For iOS Simulator: use localhost (works directly)
  // For Physical Device: use your computer's IP address on the same network
  // For Web: use localhost
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    // Check if running on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator uses 10.0.2.2 to access host machine
      return 'http://10.0.2.2:8000';
    }
    
    // iOS Simulator can use localhost directly
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:8000';
    }
    
    // Default fallback
    return 'http://localhost:8000';
  }
  
  // Alternative: Use environment variable or manual override
  // Uncomment and use this if you want to manually set the URL:
  // static const String baseUrl = String.fromEnvironment(
  //   'AI_API_URL',
  //   defaultValue: 'http://10.0.2.2:8000', // Default for Android emulator
  // );
}

