class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final String? accessToken;
  final String? refreshToken;
  final AppUser? user;  // Renamed from UserProfile

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    String? accessToken,
    String? refreshToken,
    AppUser? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
    );
  }
}

class AppUser {  // Renamed from UserProfile
  final String userId;
  final String email;
  final String fullName;
  final List<String> roles;

  AppUser({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  // Factory method to create from proto UserProfile
  factory AppUser.fromProto(dynamic protoUser) {
    return AppUser(
      userId: protoUser.userId,
      email: protoUser.email,
      fullName: protoUser.fullName,
      roles: List<String>.from(protoUser.roles),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'roles': roles,
    };
  }

  // Create from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}
