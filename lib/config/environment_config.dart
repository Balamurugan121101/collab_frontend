import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  // Environment Info
  static String get envName => dotenv.env['ENV_NAME'] ?? 'development';
  static bool get debugMode => dotenv.env['DEBUG_MODE'] == 'true';

  // Auth Service
  static String get authHost => dotenv.env['AUTH_HOST'] ?? 'localhost';
  static int get authPort => int.parse(dotenv.env['AUTH_PORT'] ?? '50051');

  // Chat Service
  static String get chatHost => dotenv.env['CHAT_HOST'] ?? 'localhost';
  static int get chatPort => int.parse(dotenv.env['CHAT_PORT'] ?? '50052');

  // Workspace Service
  static String get fileHost => dotenv.env['FILE_HOST'] ?? 'localhost';
  static int get filePort => int.parse(dotenv.env['FILE_PORT'] ?? '50053');

  // Notification Service
  static String get notificationHost => dotenv.env['NOTIFICATION_HOST'] ?? 'localhost';
  static int get notificationPort => int.parse(dotenv.env['NOTIFICATION_PORT'] ?? '50054');

  // API Configuration
  static int get apiTimeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30');
  static int get connectionTimeout => int.parse(dotenv.env['CONNECTION_TIMEOUT'] ?? '30');
  static bool get useSSL => dotenv.env['USE_SSL'] == 'true';

  // Computed Properties
  static String get authEndpoint => '$authHost:$authPort';
  static String get chatEndpoint => '$chatHost:$chatPort';
  static String get fileEndpoint => '$fileHost:$filePort';
  static String get notificationEndpoint => '$notificationHost:$notificationPort';

  // Environment Checks
  static bool get isDevelopment => envName == 'development';
  static bool get isStaging => envName == 'staging';
  static bool get isProduction => envName == 'production';

  // Load environment file
  static Future<void> load(Environment env) async {
    try {
      switch (env) {
        case Environment.dev:
          await dotenv.load(fileName: '.env.dev');
          break;
        case Environment.staging:
          await dotenv.load(fileName: '.env.staging');
          break;
        case Environment.prod:
          await dotenv.load(fileName: '.env.prod');
          break;
      }

      if (kDebugMode) {
        printConfig();
      }
    } catch (e) {
      debugPrint('❌ Failed to load environment: $e');
      rethrow;
    }
  }

  // Print configuration for debugging
  static void printConfig() {
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║     Environment Configuration          ║');
    debugPrint('╠════════════════════════════════════════╣');
    debugPrint('║ Environment: $envName');
    debugPrint('║ Debug Mode: $debugMode');
    debugPrint('║ SSL Enabled: $useSSL');
    debugPrint('╠════════════════════════════════════════╣');
    debugPrint('║ Services:');
    debugPrint('║   Auth:         $authEndpoint');
    debugPrint('║   Chat:         $chatEndpoint');
    debugPrint('║   Workspace:    $fileEndpoint');
    debugPrint('║   Notification: $notificationEndpoint');
    debugPrint('╠════════════════════════════════════════╣');
    debugPrint('║ Timeouts:');
    debugPrint('║   Connection: ${connectionTimeout}s');
    debugPrint('║   API Request: ${apiTimeout}s');
    debugPrint('╚════════════════════════════════════════╝');
  }
}

enum Environment { dev, staging, prod }
