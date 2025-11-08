import 'package:grpc/grpc.dart';
import '../storage/secure_storage_service.dart';

class TokenInterceptor extends ClientInterceptor {
  final SecureStorageService _storageService;
  String? _cachedToken;

  TokenInterceptor(this._storageService);

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
      ClientMethod<Q, R> method,
      Stream<Q> requests,
      CallOptions options,
      ClientStreamingInvoker<Q, R> invoker,
      ) {
    return super.interceptStreaming(
      method,
      requests,
      _addTokenToOptions(options),
      invoker,
    );
  }

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
      ClientMethod<Q, R> method,
      Q request,
      CallOptions options,
      ClientUnaryInvoker<Q, R> invoker,
      ) {
    return super.interceptUnary(
      method,
      request,
      _addTokenToOptions(options),
      invoker,
    );
  }

  // Synchronous method - uses cached token
  CallOptions _addTokenToOptions(CallOptions options) {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return options.mergedWith(
        CallOptions(
          metadata: {
            'authorization': 'Bearer $_cachedToken',
          },
        ),
      );
    }

    return options;
  }

  // Method to update the cached token
  Future<void> updateToken() async {
    _cachedToken = await _storageService.getAccessToken();
  }

  // Method to clear the cached token
  void clearToken() {
    _cachedToken = null;
  }
}