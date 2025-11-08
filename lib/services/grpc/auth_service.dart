import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';
import '../../protos/auth/auth.pbgrpc.dart';
import '../../protos/common/common.pb.dart';
import 'grpc_client.dart';

class AuthService {
  final ClientChannel _channel;
  late final AuthServiceClient _client;

  AuthService(this._channel) {
    _client = AuthServiceClient(
      _channel,
      interceptors: GrpcClient.getInterceptors(),
    );
    debugPrint('✅ AuthService initialized');
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    debugPrint('📤 Register request: $email');

    final request = RegisterRequest()
      ..email = email
      ..password = password
      ..fullName = fullName;

    try {
      final response = await _client.register(
        request,
        options: GrpcClient.getCallOptions(),
      );

      debugPrint('✅ Register successful');

      // Update token in interceptor for future requests
      await GrpcClient.updateToken();

      return response;
    } on GrpcError catch (e) {
      debugPrint('❌ Register error: ${e.code} - ${e.message}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    debugPrint('📤 Login request: $email');

    final request = LoginRequest()
      ..email = email
      ..password = password;

    try {
      final response = await _client.login(
        request,
        options: GrpcClient.getCallOptions(),
      );

      debugPrint('✅ Login successful');

      // Update token in interceptor for future requests
      await GrpcClient.updateToken();

      return response;
    } on GrpcError catch (e) {
      debugPrint('❌ Login error: ${e.code} - ${e.message}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    debugPrint('📤 Refresh token request');

    final request = RefreshTokenRequest()
      ..refreshToken = refreshToken;

    try {
      final response = await _client.refreshToken(
        request,
        options: GrpcClient.getCallOptions(),
      );

      debugPrint('✅ Token refreshed');

      // Update token in interceptor
      await GrpcClient.updateToken();

      return response;
    } on GrpcError catch (e) {
      debugPrint('❌ Refresh token error: ${e.code} - ${e.message}');
      throw _handleError(e);
    }
  }

  Future<bool> validateToken(String accessToken) async {
    debugPrint('📤 Validate token request');

    final request = ValidateTokenRequest()
      ..accessToken = accessToken;

    try {
      final response = await _client.validateToken(
        request,
        options: GrpcClient.getCallOptions(timeout: const Duration(seconds: 10)),
      );

      debugPrint('✅ Token validation: ${response.isValid}');
      return response.isValid;
    } catch (e) {
      debugPrint('❌ Token validation error: $e');
      return false;
    }
  }

  Future<EmptyResponse> logout(String accessToken) async {
    debugPrint('📤 Logout request');

    final request = LogoutRequest()
      ..accessToken = accessToken;

    try {
      final response = await _client.logout(
        request,
        options: GrpcClient.getCallOptions(timeout: const Duration(seconds: 10)),
      );

      debugPrint('✅ Logout successful');

      // Clear token from interceptor
      GrpcClient.clearToken();

      return response;
    } on GrpcError catch (e) {
      debugPrint('❌ Logout error: ${e.code} - ${e.message}');
      throw _handleError(e);
    }
  }

  String _handleError(GrpcError error) {
    debugPrint(' ${StatusCode.unauthenticated} ');
    debugPrint(' ${error.code} ');
    switch (error.code) {
      case StatusCode.unavailable:
        return 'Server unavailable. Please check your connection and ensure the server is running.';
      case StatusCode.deadlineExceeded:
        return 'Request timeout. Please try again.';
      case StatusCode.unauthenticated:
        return 'Invalid credentials';
      case StatusCode.alreadyExists:
        return 'Email already registered';
      case StatusCode.invalidArgument:
        return 'Invalid input. Please check your data.';
      case StatusCode.notFound:
        return 'User not found';
      case StatusCode.permissionDenied:
        return 'Permission denied';
      default:
        return error.message ?? 'An error occurred: ${error.code}';
    }
  }
}
