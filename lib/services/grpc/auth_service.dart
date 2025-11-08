import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';
import '../../protos/auth/auth.pbgrpc.dart';
import '../../protos/common/common.pb.dart';
import 'grpc_client_manager.dart';

class AuthService {
  final GrpcClientManager _manager = GrpcClientManager();
  late final AuthServiceClient _client;

  AuthService() {
    final channel = _manager.getChannel(ServiceType.auth);
    _client = AuthServiceClient(
      channel,
      interceptors: _manager.getInterceptors(ServiceType.auth),
    );
    debugPrint('✅ AuthService initialized');
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    debugPrint('📤 Register: $email');

    final request = RegisterRequest()
      ..email = email
      ..password = password
      ..fullName = fullName;

    try {
      final response = await _client.register(
        request,
        options: _manager.getCallOptions(),
      );

      await _manager.updateAllTokens();

      return response;
    } on GrpcError catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {

    final request = LoginRequest()
      ..email = email
      ..password = password;

    try {
      final response = await _client.login(
        request,
        options: _manager.getCallOptions(),
      );

      await _manager.updateAllTokens();

      return response;
    } on GrpcError catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {

    final request = RefreshTokenRequest()
      ..refreshToken = refreshToken;

    try {
      final response = await _client.refreshToken(
        request,
        options: _manager.getCallOptions(),
      );

      await _manager.updateAllTokens();

      return response;
    } on GrpcError catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> validateToken(String accessToken) async {
    final request = ValidateTokenRequest()
      ..accessToken = accessToken;

    try {
      final response = await _client.validateToken(
        request,
        options: _manager.getCallOptions(
          timeout: const Duration(seconds: 10),
        ),
      );

      return response.isValid;
    } catch (e) {
      return false;
    }
  }

  Future<EmptyResponse> logout(String accessToken) async {
    final request = LogoutRequest()
      ..accessToken = accessToken;

    try {
      final response = await _client.logout(
        request,
        options: _manager.getCallOptions(
          timeout: const Duration(seconds: 10),
        ),
      );
      _manager.clearAllTokens();

      return response;
    } on GrpcError catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(GrpcError error) {
    switch (error.code) {
      case StatusCode.unavailable:
        return 'Server unavailable. Please check your connection.';
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
        return error.message ?? 'An error occurred';
    }
  }
}
