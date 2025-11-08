import 'package:grpc/grpc.dart';
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
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final request = RegisterRequest()
      ..email = email
      ..password = password
      ..fullName = fullName;

    try {
      final response = await _client.register(
        request,
        options: GrpcClient.getCallOptions(),
      );

      // Update token in interceptor for future requests
      await GrpcClient.updateToken();

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
        options: GrpcClient.getCallOptions(),
      );

      // Update token in interceptor for future requests
      await GrpcClient.updateToken();

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
        options: GrpcClient.getCallOptions(),
      );

      // Update token in interceptor
      await GrpcClient.updateToken();

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
        options: GrpcClient.getCallOptions(),
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
        options: GrpcClient.getCallOptions(),
      );

      // Clear token from interceptor
      GrpcClient.clearToken();

      return response;
    } on GrpcError catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(GrpcError error) {
    switch (error.code) {
      case StatusCode.unauthenticated:
        return 'Invalid credentials';
      case StatusCode.alreadyExists:
        return 'Email already registered';
      case StatusCode.invalidArgument:
        return 'Invalid input. Please check your data.';
      case StatusCode.unavailable:
        return 'Server unavailable. Please try again.';
      case StatusCode.notFound:
        return 'User not found';
      case StatusCode.permissionDenied:
        return 'Permission denied';
      default:
        return error.message ?? 'An error occurred';
    }
  }
}
