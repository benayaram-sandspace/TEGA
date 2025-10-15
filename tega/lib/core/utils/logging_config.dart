import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LoggingConfig {
  static void configureLogging() {
    if (kDebugMode) {
      // Enable debug logging in debug mode
      developer.log('Debug logging enabled');
    } else {
      // Disable verbose logging in release mode
      developer.log('Release mode - verbose logging disabled');
    }
  }

  static void logVideoPlayer(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'VideoPlayer');
    }
  }

  static void logApiCall(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'APICall');
    }
  }

  static void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    // Always log errors, even in release mode
    developer.log(message, name: 'Error', error: error, stackTrace: stackTrace);
  }
}
