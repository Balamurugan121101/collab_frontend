import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static String get envName => dotenv.env['ENV_NAME'] ?? 'development';
  static String get grpcHost => dotenv.env['GRPC_HOST'] ?? 'localhost';
  static int get grpcPort => int.parse(dotenv.env['GRPC_PORT'] ?? '50051');
  static int get apiTimeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30');
  static bool get debugMode => dotenv.env['DEBUG_MODE'] == 'true';

  static String get grpcEndpoint => '$grpcHost:$grpcPort';

  static Future<void> load(Environment env) async {
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
  }
}

enum Environment { dev, staging, prod }
