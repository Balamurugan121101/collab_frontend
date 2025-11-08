import 'package:grpc/grpc.dart';
import '../storage/secure_storage_service.dart';
import 'token_interceptor.dart';

class GrpcClient {
  static ClientChannel? _channel;
  static TokenInterceptor? _tokenInterceptor;
  static final SecureStorageService _storageService = SecureStorageService();

  static ClientChannel getChannel() {
    if (_channel != null) return _channel!;

    // Create interceptor
    _tokenInterceptor = TokenInterceptor(_storageService);

    _channel = ClientChannel(
      'localhost', // Replace with your server
      port: 50051,
      options: ChannelOptions(
        credentials: const ChannelCredentials.insecure(),
        codecRegistry: CodecRegistry(
          codecs: const [GzipCodec(), IdentityCodec()],
        ),
      ),
    );

    return _channel!;
  }

  static List<ClientInterceptor> getInterceptors() {
    return _tokenInterceptor != null ? [_tokenInterceptor!] : [];
  }

  static CallOptions getCallOptions() {
    return CallOptions(
      timeout: const Duration(seconds: 30),
    );
  }

  // Update token in interceptor
  static Future<void> updateToken() async {
    if (_tokenInterceptor != null) {
      await _tokenInterceptor!.updateToken();
    }
  }

  // Clear token from interceptor
  static void clearToken() {
    _tokenInterceptor?.clearToken();
  }

  static Future<void> closeChannel() async {
    await _channel?.shutdown();
    _channel = null;
    _tokenInterceptor = null;
  }
}
