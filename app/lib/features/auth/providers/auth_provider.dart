import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userName;
  final String? userEmail;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.userName,
    this.userEmail,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userName,
    String? userEmail,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService)
      : super(AuthState(
          isAuthenticated: _authService.isLoggedIn,
          userName: _authService.userName,
          userEmail: _authService.userEmail,
        ));

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final success = await _authService.login(email, password);
    if (success) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userName: _authService.userName,
        userEmail: _authService.userEmail,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid email or password',
      );
    }
    return success;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String hospital,
    required String designation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final success = await _authService.register(
      name: name,
      email: email,
      password: password,
      hospital: hospital,
      designation: designation,
    );
    if (success) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userName: name,
        userEmail: email,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
    }
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
