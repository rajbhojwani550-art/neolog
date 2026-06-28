import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiServiceProvider));
});

class AuthService {
  final ApiService _api;
  Box get _authBox => Hive.box('auth');

  AuthService(this._api);

  bool get isLoggedIn => _authBox.get('token') != null;

  String? get token => _authBox.get('token') as String?;
  String? get userName => _authBox.get('userName') as String?;
  String? get userEmail => _authBox.get('userEmail') as String?;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _authBox.put('token', data['token']);
        await _authBox.put('userName', data['user']['name']);
        await _authBox.put('userEmail', data['user']['email']);
        return true;
      }
      return false;
    } catch (_) {
      // Offline mode: allow demo login
      if (email == 'demo@neolog.app' && password == 'demo123') {
        await _authBox.put('token', 'offline-demo-token');
        await _authBox.put('userName', 'Dr. Demo');
        await _authBox.put('userEmail', email);
        return true;
      }
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String hospital,
    required String designation,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'hospital': hospital,
        'designation': designation,
      });
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        await _authBox.put('token', data['token']);
        await _authBox.put('userName', name);
        await _authBox.put('userEmail', email);
        return true;
      }
      return false;
    } catch (_) {
      // Offline mode: register locally
      await _authBox.put('token', 'offline-token');
      await _authBox.put('userName', name);
      await _authBox.put('userEmail', email);
      return true;
    }
  }

  Future<void> logout() async {
    await _authBox.clear();
  }
}
