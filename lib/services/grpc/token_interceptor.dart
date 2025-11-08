import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

class TokenInterceptor extends ClientInterceptor {
  final SecureStorageService _storageService;
  String? _cachedToken;
  DateTime? _lastUpdate;

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

  // Add token to request metadata
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

  // Update cached token
  Future<void> updateToken() async {
    _cachedToken = await _storageService.getAccessToken();
    _lastUpdate = DateTime.now();
  }

  // Clear cached token
  void clearToken() {
    _cachedToken = null;
    _lastUpdate = null;
  }

  // Check if token needs refresh
  bool get needsRefresh {
    if (_cachedToken == null) return true;
    if (_lastUpdate == null) return true;

    final elapsed = DateTime.now().difference(_lastUpdate!);
    return elapsed.inMinutes > 5; // Refresh every 5 minutes
  }
}
