import 'dart:convert';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _api;

  ProfileService(this._api);

  Future<User> getProfile() async {
    final res = await _api.get(ApiConfig.me, auth: true);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final user = User.fromJson(data);
      _api.cacheUserInfo(user.displayName, user.email);
      return user;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to load profile');
  }

  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarType,
    String? avatarValue,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (avatarType != null) body['avatarType'] = avatarType;
    if (avatarValue != null) body['avatarValue'] = avatarValue;

    final res = await _api.put(ApiConfig.updateProfile, body, auth: true);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final user = User.fromJson(data);
      _api.cacheUserInfo(user.displayName, user.email);
      return user;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to update profile');
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _api.put(ApiConfig.changePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    }, auth: true);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Password changed';
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to change password');
  }

  Future<Map<String, dynamic>> requestEmailChange({
    required String currentPassword,
    required String newEmail,
  }) async {
    final res = await _api.post(ApiConfig.changeEmail, {
      'currentPassword': currentPassword,
      'newEmail': newEmail,
    }, auth: true);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to request email change');
  }

  Future<String> verifyNewEmail({required String token}) async {
    final res = await _api.post(ApiConfig.verifyNewEmail, {
      'token': token,
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['message'] ?? 'Email changed';
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to verify new email');
  }

  Future<void> selectBadge(String slug) async {
    final res = await _api.put(
      ApiConfig.selectBadge,
      {'slug': slug},
      auth: true,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Failed to select badge');
    }
  }
}
