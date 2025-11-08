import 'dart:io';
import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import 'token_interceptor.dart';

class GrpcClient {
  static ClientChannel? _channel;
  static TokenInterceptor? _tokenInterceptor;
  static final SecureStorageService _storageService = SecureStorageService();

  // Platform-aware host configuration
  static String getHost() {
    if (Platform.isAndroid) {
      // Android emulator: 10.0.2.2 points to host machine
      return '172.23.9.52';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'localhost';
    }
    // Default for other platforms
    return 'localhost';
  }

  static ClientChannel getChannel({
    String? host,
    int port = 50051,
    bool useSSL = false,
  }) {
    if (_channel != null) return _channel!;

    final serverHost = host ?? getHost();
    debugPrint('🔌 Connecting to gRPC server: $serverHost:$port');

    // Create interceptor
    _tokenInterceptor = TokenInterceptor(_storageService);

    _channel = ClientChannel(
      serverHost,
      port: port,
      options: ChannelOptions(
        credentials: useSSL
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
        codecRegistry: CodecRegistry(
          codecs: const [GzipCodec(), IdentityCodec()],
        ),
        connectionTimeout: const Duration(seconds: 30),
        idleTimeout: const Duration(minutes: 10),
      ),
    );

    debugPrint('✅ gRPC channel created');
    return _channel!;
  }

  static List<ClientInterceptor> getInterceptors() {
    return _tokenInterceptor != null ? [_tokenInterceptor!] : [];
  }

  static CallOptions getCallOptions({Duration? timeout}) {
    return CallOptions(
      timeout: timeout ?? const Duration(seconds: 30),
    );
  }

  // Update token in interceptor
  static Future<void> updateToken() async {
    if (_tokenInterceptor != null) {
      await _tokenInterceptor!.updateToken();
      debugPrint('🔑 Token updated in interceptor');
    }
  }

  // Clear token from interceptor
  static void clearToken() {
    _tokenInterceptor?.clearToken();
    debugPrint('🗑️ Token cleared from interceptor');
  }

  static Future<void> closeChannel() async {
    await _channel?.shutdown();
    _channel = null;
    _tokenInterceptor = null;
    debugPrint('🔌 gRPC channel closed');
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      final channel = getChannel();
      final state = channel.getConnection();
      debugPrint('📡 Connection state: ${state.toString()}');
      return true;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }
}
