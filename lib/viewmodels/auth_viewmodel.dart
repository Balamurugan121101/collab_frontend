import 'package:flutter/foundation.dart';
import '../models/auth_state.dart';
import '../services/grpc/auth_service.dart';
import '../services/storage/secure_storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storageService;
  AuthState _state = AuthState();

  AuthViewModel(this._authService, this._storageService);

  AuthState get state => _state;

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Save tokens
      await _storageService.saveTokens(
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
      );

      // Save user profile
      await _storageService.saveUserProfile(
        userId: response.user.userId,
        email: response.user.email,
        fullName: response.user.fullName,
      );

      // Convert proto UserProfile to AppUser
      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
        user: AppUser.fromProto(response.user),
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _authService.login(
        email: email,
        password: password,
      );

      // Save tokens
      await _storageService.saveTokens(
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
      );

      // Save user profile
      await _storageService.saveUserProfile(
        userId: response.user.userId,
        email: response.user.email,
        fullName: response.user.fullName,
      );

      // Convert proto UserProfile to AppUser
      _state = _state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
        user: AppUser.fromProto(response.user),
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      if (_state.accessToken != null) {
        await _authService.logout(_state.accessToken!);
      }

      // Clear all storage
      await _storageService.clearAll();

      _state = AuthState();
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear local state even if API call fails
      await _storageService.clearAll();
      _state = AuthState();
      notifyListeners();
    }
  }

  Future<void> loadSavedAuth() async {
    try {
      final hasSession = await _storageService.hasValidSession();

      if (!hasSession) {
        _state = AuthState(isAuthenticated: false);
        notifyListeners();
        return;
      }

      final accessToken = await _storageService.getAccessToken();
      final refreshToken = await _storageService.getRefreshToken();

      if (accessToken == null) {
        _state = AuthState(isAuthenticated: false);
        notifyListeners();
        return;
      }

      // Validate token with backend
      final isValid = await _authService.validateToken(accessToken);

      if (isValid) {
        // Load user profile from storage
        final profile = await _storageService.getUserProfile();

        _state = _state.copyWith(
          isAuthenticated: true,
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: profile['userId'] != null
              ? AppUser(
            userId: profile['userId']!,
            email: profile['email'] ?? '',
            fullName: profile['fullName'] ?? '',
            roles: [],
          )
              : null,
        );
        notifyListeners();
      } else {
        // Token invalid, try refresh
        if (refreshToken != null) {
          await _refreshToken(refreshToken);
        } else {
          await _storageService.clearAll();
          _state = AuthState(isAuthenticated: false);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Load saved auth error: $e');
      await _storageService.clearAll();
      _state = AuthState(isAuthenticated: false);
      notifyListeners();
    }
  }

  Future<void> _refreshToken(String refreshToken) async {
    try {
      final response = await _authService.refreshToken(refreshToken);

      await _storageService.saveTokens(
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
      );

      _state = _state.copyWith(
        isAuthenticated: true,
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _storageService.clearAll();
      _state = AuthState(isAuthenticated: false);
      notifyListeners();
    }
  }

  String _extractErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('unauthenticated') || errorStr.contains('invalid credentials')) {
      return 'Invalid email or password';
    } else if (errorStr.contains('alreadyexists') || errorStr.contains('already exists')) {
      return 'Email already registered';
    } else if (errorStr.contains('invalidargument') || errorStr.contains('invalid argument')) {
      return 'Please check your input';
    } else if (errorStr.contains('unavailable')) {
      return 'Server unavailable. Please try again.';
    } else if (errorStr.contains('notfound') || errorStr.contains('not found')) {
      return 'User not found';
    } else if (errorStr.contains('permission')) {
      return 'Permission denied';
    }

    return 'An error occurred. Please try again.';
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
