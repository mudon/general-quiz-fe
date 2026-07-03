import 'dart:convert';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/auth_tokens.dart';
import 'api_service.dart';

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  AuthResponse({required this.user, required this.tokens});
}

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final res = await _api.post(ApiConfig.register, {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final user = User.fromJson(data['user']);
      final tokens = AuthTokens.fromJson(data);
      await _api.setTokens(tokens);
      _api.cacheUserInfo(
        '${user.firstName} ${user.lastName}',
        user.email,
        tier: user.tier,
      );
      return AuthResponse(user: user, tokens: tokens);
    }

    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Registration failed');
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post(ApiConfig.login, {
      'email': email,
      'password': password,
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final user = User.fromJson(data['user']);
      final tokens = AuthTokens.fromJson(data);
      await _api.setTokens(tokens);
      _api.cacheUserInfo(
        '${user.firstName} ${user.lastName}',
        user.email,
        tier: user.tier,
      );
      return AuthResponse(user: user, tokens: tokens);
    }

    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Login failed');
  }

  Future<String> forgotPassword({required String email}) async {
    final res = await _api.post(ApiConfig.forgotPassword, {
      'email': email,
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['message'] ?? 'Reset link sent';
    }

    throw Exception(data['error'] ?? 'Request failed');
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await _api.post(ApiConfig.resetPassword, {
      'token': token,
      'password': newPassword,
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['message'] ?? 'Password reset successful';
    }
    throw Exception(data['error'] ?? 'Failed to reset password');
  }

  Future<Map<String, dynamic>> resendVerification({required String email}) async {
    final res = await _api.post(ApiConfig.resendVerification, {
      'email': email,
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return {
        'message': data['message'] ?? 'Verification sent',
        'debugToken': data['debugToken'],
      };
    }
    throw Exception(data['error'] ?? 'Failed to resend verification');
  }

  Future<String> verifyEmail({required String token}) async {
    final res = await _api.post(ApiConfig.verifyEmail, {
      'token': token,
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['message'] ?? 'Email verified';
    }
    throw Exception(data['error'] ?? 'Failed to verify email');
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }
}
